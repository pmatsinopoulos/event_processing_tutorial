import { Kafka } from "kafkajs";

const kafkaBrokers = process.env.KAFKA_BROKERS.split(",");
const topicName = process.env.TOPIC_NAME;

const kafka = new Kafka({
  clientId: `${topicName}-consumer`,
  brokers: kafkaBrokers,
});

const consumer = kafka.consumer({ groupId: `${topicName}-consumer` });

console.log("Start consuming....");

consumer.connect();
consumer.subscribe({ topic: topicName, fromBeginning: true });

consumer.run({
  eachMessage: async ({ topic, partition, message }) => {
    console.log({
      partition,
      offset: message.offset,
      value: message.value.toString(),
    });
  },
});
