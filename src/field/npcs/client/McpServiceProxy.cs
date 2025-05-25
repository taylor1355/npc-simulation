using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using ModelContextProtocol;
using ModelContextProtocol.Client;
using ModelContextProtocol.Protocol;

public class McpServiceProxy : IDisposable
{
    private readonly string _serverHost;
    private readonly int _serverPort;
    private readonly bool _debugMode;

    private IMcpClient _mcpClient = null;
    private Task<IMcpClient> _currentConnectionTask = null;
    private readonly object _lock = new object();

    public event Action Connected;
    public event Action<string> ConnectionFailed; // string errorMessage
    public event Action Disconnected;

    public McpServiceProxy(string host, int port, bool debugMode)
    {
        _serverHost = host;
        _serverPort = port;
        _debugMode = debugMode;
        // Optionally, initiate a background connection attempt on creation
        // EnsureConnectedClientAsync().ContinueWith(t => { /* Log if needed */ });
    }

    public bool IsClientInitialized => _mcpClient != null;

    private async Task<IMcpClient> EnsureConnectedClientAsync(TimeSpan? operationTimeout = null)
    {
        Task<IMcpClient> taskToExecute; // Will hold the task for the connection attempt

        lock (_lock)
        {
            if (_mcpClient != null)
            {
                return _mcpClient; // Already connected and client is available
            }

            if (_currentConnectionTask != null && !_currentConnectionTask.IsCompleted)
            {
                // An existing connection attempt is in progress
                if (_debugMode) GD.Print($"[McpServiceProxy] Attaching to ongoing connection task.");
                taskToExecute = _currentConnectionTask;
            }
            else
            {
                // No active connection attempt, or previous one completed (possibly failed).
                // Start a new one.
                if (_debugMode) GD.Print($"[McpServiceProxy] Initiating new connection.");
                _currentConnectionTask = ConnectInternalAsync();
                taskToExecute = _currentConnectionTask;
            }
        }

        TimeSpan actualTimeout = operationTimeout ?? TimeSpan.FromSeconds(15);
        var completedOuterTask = await Task.WhenAny(taskToExecute, Task.Delay(actualTimeout));

        if (completedOuterTask == taskToExecute && taskToExecute.Status == TaskStatus.RanToCompletion)
        {
            IMcpClient client = taskToExecute.Result; // Get the client from the completed task
            if (client != null)
            {
                 // Successfully connected and client is valid.
                 // The _mcpClient field is set inside ConnectInternalAsync upon successful creation by McpClientFactory.
                 // Or, if we awaited an already completed _currentConnectionTask that was successful, _mcpClient would be set.
                 // We can re-verify and set it here under lock for safety.
                lock(_lock) 
                {
                    _mcpClient = client; 
                }
                return _mcpClient;
            }
            
            // If client is null even after successful completion of taskToExecute, it's an unexpected state.
            var reasonNullClient = "Connection task completed successfully but returned a null client.";
            if (_debugMode) GD.PrintErr($"[McpServiceProxy] EnsureConnectedClientAsync critical error: {reasonNullClient}");
            ConnectionFailed?.Invoke(reasonNullClient);
            throw new InvalidOperationException($"MCP Service not available: {reasonNullClient}");
        }
        
        // Handle timeout or task failure for taskToExecute
        string failureReason = "Connection attempt failed or timed out.";
        if (taskToExecute.IsFaulted)
        {
            failureReason = taskToExecute.Exception?.GetBaseException().Message ?? "Connection task faulted.";
            if (_debugMode) GD.PrintErr($"[McpServiceProxy] Connection task faulted: {taskToExecute.Exception?.ToString()}");
        }
        else if (completedOuterTask != taskToExecute) // Timeout
        {
            failureReason = "Connection attempt timed out.";
            if (_debugMode) GD.PrintErr($"[McpServiceProxy] Connection attempt timed out waiting for task.");
        }
        
        ConnectionFailed?.Invoke(failureReason);
        if (_debugMode) GD.PrintErr($"[McpServiceProxy] EnsureConnectedClientAsync failed: {failureReason}");
        throw new InvalidOperationException($"MCP Service not available: {failureReason}");
    }

    private async Task<IMcpClient> ConnectInternalAsync()
    {
        if (_debugMode) GD.Print($"[McpServiceProxy] InternalConnect: Attempting connection to {_serverHost}:{_serverPort}.");
        try
        {
            var serverUrl = $"http://{_serverHost}:{_serverPort}";
            var sseEndpoint = $"{serverUrl}/sse";
            var clientOptions = new McpClientOptions { ClientInfo = new Implementation { Name = "Godot NPC Client (Proxy)", Version = "1.0" } };
            var transportOptions = new SseClientTransportOptions { Endpoint = new Uri(sseEndpoint) };
            var sseTransport = new SseClientTransport(transportOptions);
            
            IMcpClient createdClient = await McpClientFactory.CreateAsync(sseTransport, clientOptions);
            
            lock(_lock)
            {
                _mcpClient = createdClient;
            }

            if (_debugMode) GD.Print("[McpServiceProxy] Successfully created and assigned client instance.");
            Connected?.Invoke(); 
            return _mcpClient;
        }
        catch (Exception ex)
        {
            lock(_lock) // Ensure _mcpClient is null on failure
            {
                _mcpClient = null;
            }
            if (_debugMode) GD.PrintErr($"[McpServiceProxy] InternalConnect failed: {ex.Message}");
            // The exception will be caught by the caller (EnsureConnectedClientAsync) which handles ConnectionFailed event.
            throw; 
        }
    }

	public async Task<CallToolResponse> CallToolAsync(string toolName, Dictionary<string, object> arguments, TimeSpan? operationTimeout = null)
    {
        IMcpClient client = await EnsureConnectedClientAsync(operationTimeout);
        if (_debugMode) GD.Print($"[McpServiceProxy] Calling tool '{toolName}' with client {client.GetHashCode()}");
        return await client.CallToolAsync(toolName, arguments);
    }

    public async Task<IList<McpClientTool>> ListToolsAsync(TimeSpan? operationTimeout = null)
    {
        IMcpClient client = await EnsureConnectedClientAsync(operationTimeout);
        if (_debugMode) GD.Print($"[McpServiceProxy] Listing tools with client {client.GetHashCode()}");
        return await client.ListToolsAsync(); 
    }

    public async Task<ReadResourceResult> AccessResourceAsync(string resourceUri, TimeSpan? operationTimeout = null)
    {
        IMcpClient client = await EnsureConnectedClientAsync(operationTimeout);
        if (_debugMode) GD.Print($"[McpServiceProxy] Accessing resource '{resourceUri}' with client {client.GetHashCode()}");
        return await client.ReadResourceAsync(resourceUri);
    }
    
    public void Dispose()
    {
        IMcpClient clientToDispose = null;
        lock(_lock)
        {
            clientToDispose = _mcpClient;
            _mcpClient = null; // Prevent further use
            _currentConnectionTask = null; // Clear any pending connection task
        }

        (clientToDispose as IDisposable)?.Dispose();
        Disconnected?.Invoke();
        if (_debugMode) GD.Print("[McpServiceProxy] Disposed.");
    }
}
