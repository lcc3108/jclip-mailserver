import { ApolloServer, gql } from "apollo-server-cloud-functions";
import { typeDefs } from "@/models/graphql/types";
import { resolvers } from "@/controllers/graphql/resolvers";

export const gcpServer = new ApolloServer({
  typeDefs,
  resolvers,
  playground: false,
  introspection: false,
});
gcpServer.setGraphQLPath("/");
