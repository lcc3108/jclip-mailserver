import "@/config";
import { awsServer } from "@/controllers/graphql/aws";
import { gcpServer } from "@/controllers/graphql/gcp";

export const awsHandler = awsServer.createHandler();
export const gcpHandler = gcpServer.createHandler();
