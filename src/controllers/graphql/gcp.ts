import { ApolloServer, gql } from "apollo-server-cloud-functions";
import { typeDefs } from "@/models/graphql/types";
import { resolvers } from "@/controllers/graphql/resolvers";
import jwt from "jsonwebtoken";

export const gcpServer = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ req }) => {
    if (!req.headers.authorization) return { user: undefined };

    const token = req.headers.authorization.substr(7);

    try {
      const user = jwt.verify(token, Buffer.from(process.env.JWT_SECRET, "base64"));
      return { user };
    } catch {
      return { user: undefined };
    }
  },
  // playground: false,
  // introspection: false,
});
gcpServer.setGraphQLPath("/");
