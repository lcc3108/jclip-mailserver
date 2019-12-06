import "@/config";
import { server } from "@/controllers/graphql";

export const awsHandler = server.createHandler();
export const googleHandler = server;
