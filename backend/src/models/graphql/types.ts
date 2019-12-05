import { gql } from "apollo-server-lambda";

export const typeDefs = gql`
  type Query {
    query_test: String
  }
  type Mutation {
    mutation_test: String
  }
`;
