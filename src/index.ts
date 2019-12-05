import "@/config";
import { server } from "@/controllers/graphql";

exports.handler = server.createHandler();
