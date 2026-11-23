// The A2A operations both agents serve; each one is handed to the agent's a2a:DefaultHandler.
import ballerina/a2a;

isolated service class AgentOperations {
    *a2a:Service;

    private final a2a:DefaultHandler handler;
    private final a2a:AgentCard & readonly card;

    isolated function init(a2a:DefaultHandler handler, a2a:AgentCard card) {
        self.handler = handler;
        self.card = card.cloneReadOnly();
    }

    isolated resource function get agentCard() returns a2a:AgentCard|a2a:Error => self.card;

    isolated resource function post message\:send(a2a:Context context, a2a:SendMessageRequest request)
            returns a2a:Task|a2a:Message|a2a:Error => self.handler.handleSendMessage(context, request);

    isolated resource function post message\:stream(a2a:Context context, a2a:SendMessageRequest request)
            returns stream<a2a:StreamResponse, a2a:Error?>|a2a:Error =>
        self.handler.handleSendStreamingMessage(context, request);

    isolated resource function get tasks/[string id](a2a:Context context, a2a:GetTaskRequest request)
            returns a2a:Task|a2a:Error => self.handler.handleGetTask(context, request);

    isolated resource function get tasks/[string id]/subscribe(a2a:Context context, a2a:SubscribeToTaskRequest request)
            returns stream<a2a:StreamResponse, a2a:Error?>|a2a:Error =>
        self.handler.handleSubscribeToTask(context, request);

    isolated resource function post tasks/[string id]/cancel(a2a:Context context, a2a:CancelTaskRequest request)
            returns a2a:Task|a2a:Error => self.handler.handleCancelTask(context, request);
}
