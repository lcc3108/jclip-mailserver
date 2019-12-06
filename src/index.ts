import "@/config";
import { server } from "@/controllers/graphql";

export const aws_handler = server.createHandler();
export const google_handler = server;
