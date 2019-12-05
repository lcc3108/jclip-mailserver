import { gql } from "apollo-server-express";

export const typeDefs = gql`
  type Query {
    query_test: String
  }
  type Mutation {
    mutation_test: String
  }
`;
