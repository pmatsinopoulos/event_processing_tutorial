import { Kafka } from "kafkajs";
import pg from "pg";

const { Pool } = pg;

const dbUser = process.env.DB_USERNAME;
const dbHost = process.env.DB_HOST;
const dbDatabase = process.env.DB_DATABASE;
const dbPassword = process.env.DB_PASSWORD;
const dbPort = process.env.DB_PORT;

const dbCredentials = {
  user: dbUser,
  host: dbHost,
  database: dbDatabase,
  password: dbPassword,
  port: dbPort,
};

const pool = new Pool(dbCredentials);

const insertRecordIntoDb = async ({ broadcastId }) => {
  const sqlStatement = `
    INSERT INTO broadcasts (broadcast_id) values ($1) RETURNING id
  `;

  const values = [broadcastId];

  return pool.query(sqlStatement, values);
};

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
    const value = message.value.toString();
    console.debug({
      partition,
      offset: message.offset,
      value,
    });

    const id = await insertRecordIntoDb({ broadcastId: value });

    console.debug(`broadcast record created with id: ${id.rows[0].id}`);
  },
});
