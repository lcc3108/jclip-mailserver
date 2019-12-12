import { ApolloServer } from "apollo-server-lambda";
import { typeDefs } from "@/models/graphql/types";
import { resolvers } from "@/controllers/graphql/resolvers";
import jwt from "jsonwebtoken";

export const awsServer = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ event }) => {
    if (!event.headers.authorization) return { user: undefined };

    const token = event.headers.authorization.substr(7);

    try {
      const user = jwt.verify(token, Buffer.from(process.env.JWT_SECRET, "base64"));
      return { user };
    } catch {
      return { user: undefined };
    }
  },
  playground: false,
  introspection: false,
});
awsServer.setGraphQLPath("/");
