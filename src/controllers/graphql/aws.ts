import { ApolloServer } from "apollo-server-lambda";
import { typeDefs } from "@/models/graphql/types";
import { resolvers } from "@/controllers/graphql/resolvers";
// Construct a schema, using GraphQL schema language

export const awsServer = new ApolloServer({
  typeDefs,
  resolvers,
  playground: false,
  introspection: false,
});
awsServer.setGraphQLPath("/");
