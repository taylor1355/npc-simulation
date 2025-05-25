using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using ModelContextProtocol;
using ModelContextProtocol.Client;
using ModelContextProtocol.Protocol;
using System.Text.Json;


// Tracks information about a pending MCP request
public class PendingRequest 
{
	public string ToolName { get; set; }
	public string AgentId { get; set; }
	public DateTime RequestTime { get; set; } = DateTime.Now;
}

public partial class McpSdkClient : Node
{
	[Signal]
	public delegate void RequestCompletedEventHandler(string requestId, Godot.Collections.Dictionary response);
	[Signal]
	public delegate void RequestErrorEventHandler(string requestId, string errorMessage);

	[Export] public string ServerHost { get; set; } = "localhost";
	[Export] public int ServerPort { get; set; } = 3000;
	[Export] public bool DebugMode { get; set; } = true;

	private McpServiceProxy _serviceProxy;
	private Dictionary<string, PendingRequest> _pendingRequests = new Dictionary<string, PendingRequest>();
	
	public override void _Ready()
	{
		_serviceProxy = new McpServiceProxy(ServerHost, ServerPort, DebugMode);
		// Optional: Subscribe to general proxy events if needed for UI or broader status
		// _serviceProxy.ConnectionFailed += (errMsg) => 
		// {
		//     GD.PrintErr($"[McpSdkClient] General connection failure from proxy: {errMsg}");
		//     EmitSignal(SignalName.RequestError, "GENERAL_CONNECTION_FAILURE", errMsg);
		// };
		// _serviceProxy.Connected += () => 
		// {
		//     if(DebugMode) GD.Print("[McpSdkClient] ServiceProxy reported connection established.");
		// };
	}

    public override void _Notification(int what)
    {
        if (what == NotificationPredelete)
        {
            (_serviceProxy as IDisposable)?.Dispose();
        }
    }

	public async void CreateAgent(string requestId, string agentId, Godot.Collections.Dictionary config)
	{
		_pendingRequests[requestId] = new PendingRequest { ToolName = "create_agent", AgentId = agentId };
		var configDict = GodotToCSharpDictionary(config);
		
		try
		{
			var response = await _serviceProxy.CallToolAsync("create_agent", new Dictionary<string, object>
			{
				["agent_id"] = agentId,
				["config"] = configDict
			});
			
			if (DebugMode) 
			{
				string rawResponseText = (response?.Content?.Count > 0) ? response.Content[0].Text : "null or empty response";
				GD.Print($"[McpSdkClient DEBUG] Raw create_agent response: {rawResponseText}");
			}

			if (response == null || response.Content == null || response.Content.Count == 0)
			{
				EmitError(requestId, "Received null or empty response from server for create_agent.");
				return;
			}
			
			var responseStr = response.Content[0].Text;
			try
			{
				var jsonDoc = JsonDocument.Parse(responseStr);
				var root = jsonDoc.RootElement;
				var parsedResponse = new Dictionary<string, object>();
				foreach (var prop in root.EnumerateObject())
				{
					parsedResponse[prop.Name] = GetJsonElementValue(prop.Value);
				}
				if (DebugMode) GD.Print($"[McpSdkClient DEBUG] Parsed JSON for create_agent: {JsonSerializer.Serialize(parsedResponse)}");
				EmitResponse(requestId, parsedResponse);
			}
			catch (JsonException jsonEx)
			{
				GD.PrintErr($"[McpSdkClient] Failed to parse create_agent JSON: {jsonEx.Message}. Raw: '{responseStr}'");
				EmitError(requestId, $"Failed to parse server response for create_agent: {jsonEx.Message}");
			}
		}
		catch (InvalidOperationException opEx) // From McpServiceProxy for connection issues
		{
			GD.PrintErr($"[McpSdkClient] CreateAgent Error (Connection/Proxy): {opEx.Message}");
			EmitError(requestId, opEx.Message);
		}
		catch (Exception ex) // Other errors during the call or parsing
		{
			GD.PrintErr($"[McpSdkClient] CreateAgent Generic Error: {ex.ToString()}");
			EmitError(requestId, ex.Message);
		}
		finally
		{
			_pendingRequests.Remove(requestId);
		}
	}

	public async void ProcessObservation(string requestId, string agentId, string observation, Godot.Collections.Array availableActions)
	{
		_pendingRequests[requestId] = new PendingRequest { ToolName = "process_observation", AgentId = agentId };
		var actionsList = GodotToCSharpArray(availableActions);
		
		try
		{
			var response = await _serviceProxy.CallToolAsync("process_observation", new Dictionary<string, object>
			{
				["agent_id"] = agentId,
				["observation"] = observation,
				["available_actions"] = actionsList
			});

			if (response == null || response.Content == null || response.Content.Count == 0)
			{
				EmitError(requestId, "Received null or empty response from server for process_observation.");
				return;
			}
			
			var formattedResponse = ParseObservationResponse(response); // Handles its own JSON errors
			EmitResponse(requestId, formattedResponse);
		}
		catch (InvalidOperationException opEx)
		{
			GD.PrintErr($"[McpSdkClient] ProcessObservation Error (Connection/Proxy): {opEx.Message}");
			EmitError(requestId, opEx.Message);
		}
		catch (Exception ex)
		{
			GD.PrintErr($"[McpSdkClient] ProcessObservation Generic Error: {ex.ToString()}");
			EmitError(requestId, ex.Message);
		}
		finally
		{
			_pendingRequests.Remove(requestId);
		}
	}
	
	public async void CleanupAgent(string requestId, string agentId)
	{
		_pendingRequests[requestId] = new PendingRequest { ToolName = "cleanup_agent", AgentId = agentId };
		try
		{
			// Assuming CallToolAsync returns a CallToolResponse, even if content is minimal for cleanup
			await _serviceProxy.CallToolAsync("cleanup_agent", new Dictionary<string, object> { ["agent_id"] = agentId });
			
			var formattedResponse = new Dictionary<string, object> { ["status"] = "removed", ["agent_id"] = agentId };
			EmitResponse(requestId, formattedResponse);
		}
		catch (InvalidOperationException opEx)
		{
			GD.PrintErr($"[McpSdkClient] CleanupAgent Error (Connection/Proxy): {opEx.Message}");
			EmitError(requestId, opEx.Message);
		}
		catch (Exception ex)
		{
			GD.PrintErr($"[McpSdkClient] CleanupAgent Generic Error: {ex.ToString()}");
			EmitError(requestId, ex.Message);
		}
		finally
		{
			_pendingRequests.Remove(requestId);
		}
	}

	public async void GetResource(string requestId, string resourcePath)
	{
		_pendingRequests[requestId] = new PendingRequest { ToolName = "get_resource", AgentId = ExtractAgentIdFromResourcePath(resourcePath) };
		try
		{
			ReadResourceResult response = await _serviceProxy.AccessResourceAsync(resourcePath);

			if (response == null || response.Contents == null || response.Contents.Count == 0)
			{
				EmitError(requestId, "Received null or empty content list from server for get_resource.");
				return;
			}

			// Expecting the first content item to be TextResourceContents for agent info.
			var contentItem = response.Contents[0];
			if (contentItem is TextResourceContents textContent)
			{
				if (string.IsNullOrEmpty(textContent.Text))
				{
					EmitError(requestId, "Received empty text content from server for get_resource.");
					return;
				}
				var formattedResponse = ParseResourceResponse(textContent, resourcePath); 
				EmitResponse(requestId, formattedResponse);
			}
			else
			{
				EmitError(requestId, $"Expected text content, but received {contentItem.GetType().Name} for get_resource.");
				return;
			}
		}
		catch (InvalidOperationException opEx)
		{
			GD.PrintErr($"[McpSdkClient] GetResource Error (Connection/Proxy): {opEx.Message}");
			EmitError(requestId, opEx.Message);
		}
		catch (Exception ex)
		{
			GD.PrintErr($"[McpSdkClient] GetResource Generic Error: {ex.ToString()}");
			EmitError(requestId, ex.Message);
		}
		finally
		{
			_pendingRequests.Remove(requestId);
		}
	}
	
	public async void ListTools(string requestId)
	{
		_pendingRequests[requestId] = new PendingRequest { ToolName = "list_tools" };
		try
		{
			IList<McpClientTool> toolsResponse = await _serviceProxy.ListToolsAsync();
			var toolsList = new List<object>(); 
			
			if (toolsResponse != null)
			{
				foreach (var tool in toolsResponse)
				{
					var toolInfo = new Godot.Collections.Dictionary
					{
						{ "name", tool.Name },
						{ "description", tool.Description ?? "" }
					};
					toolsList.Add(toolInfo);
				}
			}
			
			var simpleResponse = new Dictionary<string, object> { ["tools"] = toolsList };
			EmitResponse(requestId, simpleResponse);
		}
		catch (InvalidOperationException opEx)
		{
			GD.PrintErr($"[McpSdkClient] ListTools Error (Connection/Proxy): {opEx.Message}");
			EmitError(requestId, opEx.Message);
		}
		catch (Exception ex)
		{
			GD.PrintErr($"[McpSdkClient] ListTools Generic Error: {ex.ToString()}");
			EmitError(requestId, ex.Message);
		}
		finally
		{
			_pendingRequests.Remove(requestId);
		}
	}

	// --- Helper methods for parsing and data conversion ---
	private Dictionary<string, object> ParseObservationResponse(CallToolResponse response)
	{
		var responseJson = response.Content[0].Text; 
		JsonDocument jsonDoc;
		try { jsonDoc = JsonDocument.Parse(responseJson); }
		catch (JsonException ex)
		{
			GD.PrintErr($"[McpSdkClient] ParseObservationResponse JSON error: {ex.Message}. Raw: '{responseJson}'");
			return new Dictionary<string, object>
			{
				["action"] = "idle",
				["parameters"] = new Dictionary<string, object>(),
				["error"] = $"Failed to parse response: {ex.Message}"
			};
		}
		var root = jsonDoc.RootElement;
		var result = new Dictionary<string, object>();
		
		// Extract action name
		if (root.TryGetProperty("action", out var actionElement))
		{
			result["action"] = actionElement.GetString();
			
			// Extract parameters if present
			if (root.TryGetProperty("parameters", out var paramsElement))
			{
				// Convert JSON parameters to dictionary
				var parameters = new Dictionary<string, object>();
				foreach (var param in paramsElement.EnumerateObject())
				{
					parameters[param.Name] = GetJsonElementValue(param.Value);
				}
				result["parameters"] = parameters;
			}
			else
			{
				// Default empty parameters
				result["parameters"] = new Dictionary<string, object>();
			}
		}
		else if (root.TryGetProperty("status", out var statusElement) && statusElement.GetString() == "error")
		{
			result["error"] = root.TryGetProperty("message", out var msg) ? msg.GetString() : "Unknown error from server.";
			result["action"] = "idle"; 
			result["parameters"] = new Dictionary<string, object>();
		}
		else
		{
			result["action"] = "idle"; 
			result["parameters"] = new Dictionary<string, object>();
			if (DebugMode) GD.Print($"[McpSdkClient] Unknown response format in ParseObservationResponse. Raw: '{responseJson}'");
		}
		return result;
	}
	
	private object GetJsonElementValue(JsonElement element)
	{
		switch (element.ValueKind)
		{
			case JsonValueKind.String: return element.GetString();
			case JsonValueKind.Number: return element.TryGetInt32(out int i) ? i : element.GetDouble();
			case JsonValueKind.True: return true;
			case JsonValueKind.False: return false;
			case JsonValueKind.Object:
				var obj = new Dictionary<string, object>();
				foreach (var property in element.EnumerateObject())
				{
					obj[property.Name] = GetJsonElementValue(property.Value);
				}
				return obj;
			case JsonValueKind.Array:
				var arr = new List<object>();
				foreach (var item in element.EnumerateArray())
				{
					arr.Add(GetJsonElementValue(item));
				}
				return arr;
			default: return null;
		}
	}

	private string ExtractAgentIdFromResourcePath(string resourcePath)
	{
		if (resourcePath != null && resourcePath.StartsWith("agent://"))
		{
			var parts = resourcePath.Substring(8).Split('/');
			if (parts.Length > 0) return parts[0];
		}
		return string.Empty;
	}
	
	private Dictionary<string, object> ParseResourceResponse(TextResourceContents textContent, string resourcePath)
	{
		var responseJson = textContent.Text;
		JsonDocument jsonDoc;
		try { jsonDoc = JsonDocument.Parse(responseJson); }
		catch (JsonException ex)
		{
			GD.PrintErr($"[McpSdkClient] ParseResourceResponse JSON error: {ex.Message}. Raw: '{responseJson}'");
			return new Dictionary<string, object>
			{
				["status"] = "error",
				["message"] = $"Failed to parse response: {ex.Message}"
			};
		}
		
		var root = jsonDoc.RootElement;
		var result = new Dictionary<string, object>();

		// Handle agent info resource (this specific logic might be part of a dedicated parser in a larger refactor)
		if (resourcePath.Contains("/info") && root.TryGetProperty("status", out var statusElem))
		{
			result["status"] = statusElem.GetString();

			// Get traits if present
			if (root.TryGetProperty("traits", out var traitsElem))
			{
				var traits = new List<string>();
				foreach (var trait in traitsElem.EnumerateArray())
				{
					traits.Add(trait.GetString());
				}
				result["traits"] = traits;
			}

			// Get working memory if present
			if (root.TryGetProperty("working_memory", out var memoryElem))
			{
				result["working_memory"] = memoryElem.GetString();
			}

			// Error handling
			if (statusElem.GetString() == "error" &&
				root.TryGetProperty("message", out var messageElem))
			{
				result["message"] = messageElem.GetString();
			}
		}
		else
		{
			// For unknown resource types, convert the whole JSON to a dictionary
			foreach (var property in root.EnumerateObject())
			{
				result[property.Name] = GetJsonElementValue(property.Value);
			}
		}
		return result;
	}

	private void EmitResponse(string requestId, Dictionary<string, object> response)
	{
		if (DebugMode)
		{
			string requestType = _pendingRequests.TryGetValue(requestId, out var request) ? request.ToolName : "unknown_request_type";
			GD.Print($"[McpSdkClient] MCP response for {requestId} ({requestType}): {JsonSerializer.Serialize(response)}");
		}
		EmitSignal(SignalName.RequestCompleted, requestId, CSharpToGodotDictionary(response));
	}

	private void EmitError(string requestId, string errorMessage)
	{
		var requestType = _pendingRequests.TryGetValue(requestId, out var request) ? 
			request.ToolName : "unknown";
		GD.PrintErr($"MCP error for {requestId} ({requestType}): {errorMessage}");
		
		// Create error response with consistent format for GDScript client
		var errorResponse = CSharpToGodotDictionary(new Dictionary<string, object> 
		{
			["status"] = "error",
			["message"] = errorMessage
		});
		
		EmitSignal(SignalName.RequestError, requestId, errorMessage);
		EmitSignal(SignalName.RequestCompleted, requestId, errorResponse); // Also emit completed so GDScript can handle error in one place
	}

	private Dictionary<string, object> GodotToCSharpDictionary(Godot.Collections.Dictionary godotDict)
	{
		var result = new Dictionary<string, object>();
		if (godotDict == null) return result;

		foreach (var key in godotDict.Keys)
		{
			var value = godotDict[key];
			string keyStr = key.ToString();
			if (value.VariantType == Variant.Type.Dictionary) result[keyStr] = GodotToCSharpDictionary((Godot.Collections.Dictionary)value);
			else if (value.VariantType == Variant.Type.Array) result[keyStr] = GodotToCSharpArray((Godot.Collections.Array)value);
			else result[keyStr] = value.Obj;
		}
		return result;
	}
	
	private List<object> GodotToCSharpArray(Godot.Collections.Array godotArray)
	{
		var result = new List<object>();
		if (godotArray == null) return result;
		
		foreach (var item in godotArray)
		{
			if (item.VariantType == Variant.Type.Dictionary) result.Add(GodotToCSharpDictionary((Godot.Collections.Dictionary)item));
			else if (item.VariantType == Variant.Type.Array) result.Add(GodotToCSharpArray((Godot.Collections.Array)item));
			else result.Add(item.Obj);
		}
		return result;
	}
	
	private Variant ObjectToVariant(object value, string context = "")
	{
		if (value == null)
		{
			if (!string.IsNullOrEmpty(context)) GD.PrintErr($"[McpSdkClient] ObjectToVariant: Unexpected null {context}");
			return new Variant();
		}

		if (value is bool b) return Variant.CreateFrom(b);
		if (value is int i) return Variant.CreateFrom(i);
		if (value is long l) return Variant.CreateFrom(l);
		if (value is float f) return Variant.CreateFrom(f);
		if (value is double d) return Variant.CreateFrom(d);
		if (value is string s) return Variant.CreateFrom(s);
		if (value is Dictionary<string, object> dict) return CSharpToGodotDictionary(dict);
		if (value is List<object> list) return CSharpToGodotArray(list);
		if (value is System.Collections.IEnumerable enumerable && !(value is string))
		{
			var tempList = new List<object>();
			foreach (var item in enumerable) tempList.Add(item);
			return CSharpToGodotArray(tempList);
		}
		GD.PrintErr($"[McpSdkClient] ObjectToVariant: Unsupported type {value.GetType().Name} {context}");
		return new Variant();
	}
	
	private Godot.Collections.Dictionary CSharpToGodotDictionary(Dictionary<string, object> csharpDict)
	{
		var result = new Godot.Collections.Dictionary();
		if (csharpDict == null) return result;

		foreach (var pair in csharpDict)
		{
			result[pair.Key] = ObjectToVariant(pair.Value, $"for key '{pair.Key}'");
		}
		
		return result;
	}
	
	private Godot.Collections.Array CSharpToGodotArray(List<object> array)
	{
		var result = new Godot.Collections.Array();
		if (array == null) return result;

		for (int i = 0; i < array.Count; i++)
		{
			result.Add(ObjectToVariant(array[i], $"in array at index {i}"));
		}
		
		return result;
	}
}
