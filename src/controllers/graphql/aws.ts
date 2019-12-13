import { ApolloServer } from "apollo-server-lambda";
import { typeDefs } from "@/models/graphql/types";
import { resolvers } from "@/controllers/graphql/resolvers";
import jwt from "jsonwebtoken";
import { schemaDirectives } from "@/models/graphql/directives";

export const awsServer = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ event }) => {
    if (!event.headers.authorization) {
      console.log("no header");
      return { user: undefined };
    }

    const token = event.headers.authorization.substr(7);
    console.log("token", token);

    try {
      const user = jwt.verify(token, process.env.JWT_SECRET);
      console.log("auth success");

      return { user };
    } catch {
      console.log("auth fail");

      return { user: undefined };
    }
  },
  schemaDirectives,
  playground: false,
  introspection: false,
});
awsServer.setGraphQLPath("/");
