// Trip Planner Agent: a Claude-backed A2A agent built with ballerina/a2a and ballerina/ai, for WSO2 Agent Manager.
//
// Agent Manager expects one port with the card at /.well-known/agent-card.json and HTTP+JSON under /rest, which is
// where a2a:RestListener serves them by default. Its gateway does the authentication, so the listener has none.
// Asks which city when none is named (INPUT_REQUIRED), then plans a day. Needs ANTHROPIC_API_KEY.
import ballerina/a2a;
import ballerina/ai;
import ballerina/log;
import ballerina/os;
import ballerina/uuid;
import ballerinax/ai.anthropic;

listener a2a:RestListener plannerListener = new (9090);

final ai:ModelProvider model = check new anthropic:ModelProvider(os:getEnv("ANTHROPIC_API_KEY"), anthropic:CLAUDE_HAIKU_4_5);

final a2a:AgentCard plannerCard = {
    name: "Trip Planner Agent",
    description: "Plans short, one-day trip itineraries",
    version: "1.0.0",
    skills: [
        {
            id: "plan-day-trip",
            name: "Plan a day trip",
            description: "Plans a one-day itinerary for a city. Asks which city when none is named.",
            tags: ["travel"],
            examples: ["Plan me a day trip to Kandy", "Plan me a day trip"]
        }
    ],
    defaultInputModes: ["text"],
    defaultOutputModes: ["text"],
    capabilities: {},
    supportedInterfaces: []
};

isolated class TripPlannerExecutor {
    *a2a:AgentExecutor;

    private final ai:Agent brain;

    isolated function init() returns error? {
        self.brain = check new (
            systemPrompt = {
                role: "Trip Planner",
                instructions: string `You plan a short, one-day trip.
If you do not know the city yet, reply with exactly: NEEDS_INFO: <one short question asking which city>
Once you know the city (from this message or earlier in the conversation), reply with exactly:
ITINERARY: <3 short activities for that city, one sentence each>
Never use any other format.`
            },
            model = model
        );
    }

    public isolated function execute(a2a:RequestContext context, a2a:TaskUpdater updater)
            returns a2a:Message|a2a:Error? {
        string text = textOf(context.message);
        log:printInfo("Trip Planner request", taskId = updater.getTaskId(), contextId = updater.getContextId(),
                text = text);
        check updater.working();
        // The A2A context id is the conversation, so the planner remembers what it asked.
        string|error reply = self.brain.run(text, sessionId = updater.getContextId());
        if reply is error {
            log:printError("Model call failed", 'error = reply);
            check updater.failed({messageId: uuid:createType4AsString(), role: a2a:ROLE_AGENT,
                parts: [{text: "The trip planner could not reach its model."}]});
            return;
        }
        string trimmed = reply.trim();
        if trimmed.startsWith("NEEDS_INFO:") {
            check updater.requireInput({messageId: uuid:createType4AsString(), role: a2a:ROLE_AGENT,
                parts: [{text: trimmed.substring("NEEDS_INFO:".length()).trim()}]});
            return;
        }
        string itinerary = trimmed.startsWith("ITINERARY:") ? trimmed.substring("ITINERARY:".length()).trim() : trimmed;
        check updater.addArtifact([{text: itinerary}]);
        check updater.complete();
        return;
    }
}

isolated function textOf(a2a:Message message) returns string {
    string text = "";
    foreach a2a:Part part in message.parts {
        string? t = part?.text;
        if t is string {
            text += t;
        }
    }
    return text;
}

function init() returns error? {
    TripPlannerExecutor planner = check new ();
    check plannerListener.attach(new AgentOperations(new a2a:DefaultHandler(planner), plannerCard));
}
