import { Kafka } from "kafkajs";
console.log("Lambda function starting...");

const brokers = process.env.KAFKA_BROKERS.split(",");
const topicName = process.env.TOPIC_NAME;

console.debug("Brokers: ", brokers);

const kafka = new Kafka({
  clientId: `${topicName}-producer`,
  brokers: brokers,
});

let error = null;

const producer = kafka.producer();

try {
  await producer.connect();
} catch (e) {
  console.error(`ERROR caught: ${e}`);
  error = e;
}

export const handler = async (event, context) => {
  const promise = new Promise((resolve, reject) => {
    if (error) {
      console.error("Rejecting....");
      reject(error);
    } else {
      (async () => {
        console.debug("Event:", event);
        console.debug("Publishing a new event");

        const broadcastId = event["broadcastId"];
        try {
          await producer.send({
            topic: topicName,
            allowAutoTopicCreation: true,
            messages: [
              {
                key: broadcastId,
                value: `This is event for broadcast: ${broadcastId}`,
              },
            ],
          });
          resolve({ status: "200" });
        } catch (e) {
          console.error("Error publishing an event");
          reject(e);
        }
      })();
    }
  });
  return promise;
};
