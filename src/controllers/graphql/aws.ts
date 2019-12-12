import { ApolloServer } from "apollo-server-lambda";
import { typeDefs } from "@/models/graphql/types";
import { resolvers } from "@/controllers/graphql/resolvers";
import jwt from "jsonwebtoken";
import { schemaDirectives } from "@/models/graphql/directives";

export const awsServer = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ event }) => {
    if (!event.headers.authorization) return { user: undefined };

    const token = event.headers.authorization.substr(7);

    try {
      const user = jwt.verify(token, process.env.JWT_SECRET);
      return { user };
    } catch {
      return { user: undefined };
    }
  },
  schemaDirectives,
  playground: false,
  introspection: false,
});
awsServer.setGraphQLPath("/");
