import { requestGraphQLAsync } from "@/test/http";
import { expect } from "chai";

describe("mutation test", () => {
  it("gql mutation call", async () => {
    const result = await requestGraphQLAsync({ query: "mutation{ mutation_test }" });
    expect(result.text).to.have.string("mutation test");
  });
});

// https://www.chaijs.com/api/bdd/
//
