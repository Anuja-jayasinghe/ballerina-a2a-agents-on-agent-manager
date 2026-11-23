// Weather Agent: an A2A agent built with ballerina/a2a, for WSO2 Agent Manager.
//
// Agent Manager expects one port with the card at /.well-known/agent-card.json and HTTP+JSON under /rest, which is
// where a2a:RestListener serves them by default. Its gateway does the authentication, so the listener has none.
// Scripted forecasts, no model: asks which city when the message names none (INPUT_REQUIRED).
import ballerina/a2a;
import ballerina/log;
import ballerina/uuid;

listener a2a:RestListener weatherListener = new (9090);

final readonly & map<string> FORECASTS = {
    "colombo": "31°C, humid, an afternoon shower likely",
    "kandy": "26°C, partly cloudy, light rain in the evening",
    "galle": "29°C, sunny with a sea breeze",
    "porto": "19°C, clear skies",
    "lisbon": "22°C, sunny"
};

final a2a:AgentCard weatherCard = {
    name: "Weather Agent",
    description: "Gives today's forecast for a few cities",
    version: "1.0.0",
    skills: [
        {
            id: "forecast",
            name: "Today's forecast",
            description: "Today's forecast for Colombo, Kandy, Galle, Porto or Lisbon. Asks which city when none is named.",
            tags: ["weather"],
            examples: ["What's the weather in Kandy?"]
        }
    ],
    defaultInputModes: ["text"],
    defaultOutputModes: ["text"],
    capabilities: {},
    supportedInterfaces: []
};

isolated class WeatherExecutor {
    *a2a:AgentExecutor;

    public isolated function execute(a2a:RequestContext context, a2a:TaskUpdater updater)
            returns a2a:Message|a2a:Error? {
        string text = textOf(context.message);
        log:printInfo("Weather request", taskId = updater.getTaskId(), contextId = updater.getContextId(), text = text);
        string lower = text.toLowerAscii();
        foreach [string, string] [city, forecast] in FORECASTS.entries() {
            if lower.includes(city) {
                string name = city.substring(0, 1).toUpperAscii() + city.substring(1);
                check updater.addArtifact([{text: string `${name}: ${forecast}`}]);
                check updater.complete();
                return;
            }
        }
        check updater.requireInput({messageId: uuid:createType4AsString(), role: a2a:ROLE_AGENT,
            parts: [{text: "Which city? I have forecasts for Colombo, Kandy, Galle, Porto and Lisbon."}]});
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
    check weatherListener.attach(new AgentOperations(new a2a:DefaultHandler(new WeatherExecutor()), weatherCard));
}
