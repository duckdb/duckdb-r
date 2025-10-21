# we can create comparison expressions with appropriate operators

    Code
      expr_comparison("=", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 = 42)

---

    Code
      expr_comparison("!=", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 != 42)

---

    Code
      expr_comparison(">", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 > 42)

---

    Code
      expr_comparison("<", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 < 42)

---

    Code
      expr_comparison(">=", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 >= 42)

---

    Code
      expr_comparison("<=", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 <= 42)

# we cannot create comparison expressions with inappropriate operators

    Code
      expr_comparison("z", list(expr_constant(-42), expr_constant(42L)))
    Condition
      Error:
      ! expr_comparison: Invalid comparison operator

---

    Code
      expr_comparison("2", list(expr_constant(-42), expr_constant(42L)))
    Condition
      Error:
      ! expr_comparison: Invalid comparison operator

---

    Code
      expr_comparison("-", list(expr_constant(-42), expr_constant(42L)))
    Condition
      Error:
      ! expr_comparison: Invalid comparison operator

# the altrep-conversion for relations works

    Code
      last_rel
    Message
      DuckDB Relation: 
      ---------------------
      --- Relation Tree ---
      ---------------------
      r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - Sepal.Length (DOUBLE)
      - Sepal.Width (DOUBLE)
      - Petal.Length (DOUBLE)
      - Petal.Width (DOUBLE)
      - Species (VARCHAR)
      

# rel_tostring()

    Code
      writeLines(rel_tostring(proj))
    Output
      ---------------------
      --- Relation Tree ---
      ---------------------
      Projection [x as x]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - x (DOUBLE)
      

---

    Code
      writeLines(rel_tostring(proj, "tree"))
    Output
      Projection [x as x]
        r_dataframe_scan(0x...)

# rel_explain()

    Code
      writeLines(rel_explain_df(proj)[[2]])
    Output
      ┌───────────────────────────┐
      │     R_DATAFRAME_SCAN      │
      │    ────────────────────   │
      │      Text: data.frame     │
      │       Projections: x      │
      │                           │
      │           ~1 row          │
      └───────────────────────────┘
      

---

    Code
      writeLines(rel_explain_df(proj, "analyze")[[2]])
    Output
      Query profiling is disabled. Use 'PRAGMA enable_profiling;' to enable profiling!

---

    Code
      writeLines(rel_explain_df(proj, "standard", "json")[[2]])
    Output
      [
          {
              "name": "R_DATAFRAME_SCAN ",
              "children": [],
              "extra_info": {
                  "Text": "data.frame",
                  "Projections": "x",
                  "Estimated Cardinality": "1"
              }
          }
      ]

---

    Code
      writeLines(rel_explain_df(proj, "analyze", "json")[[2]])
    Output
      {
          "result": "disabled"
      }

---

    Code
      writeLines(rel_explain_df(proj, "standard", "html")[[2]])
    Output
      
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <link rel="stylesheet" href="https://unpkg.com/treeflex/dist/css/treeflex.css">
          <title>DuckDB Query Plan</title>
          
          <style>
              body {
                  font-family: Arial, sans-serif;
              }
      
              .tf-tree .tf-nc {
                  padding: 0px;
                  border: 1px solid #E5E5E5;
              }
      
              .tf-nc {
                  border-radius: 0.5rem;
                  padding: 0px;
                  min-width: 150px;
                  width: auto;
                  background-color: #FAFAFA;
                  text-align: center;
                  position: relative;
              }
      
              .collapse_button {
                  position:relative;
                  color: black;
                  z-index: 2;
                  width: 2em;
                  background-color: white;
                  height: 2em;
                  border-radius: 50%;
                  top: 2.25em;
              }
      
              .collapse_button:hover {
                  background-color: #f0f0f0; /* Light gray */
              }
      
              .collapse_button:active {
                  background-color: #e0e0e0; /* Slightly darker gray */
              }
      
              .hidden {
                  display: none !important;
              }
      
              .title {
                  font-weight: bold;
                  padding-bottom: 5px;
                  color: #fff100;
                  box-sizing: border-box;
                  background-color: black;
                  border-top-left-radius: 0.5rem;
                  border-top-right-radius: 0.5rem;
                  padding: 10px;
              }
      
              .content {
                  border-top: 1px solid #000;
                  text-align: center;
                  border-bottom-left-radius: 0.5rem;
                  border-bottom-right-radius: 0.5rem;
                  padding: 10px;
              }
      
              .sub-title {
                  color: black;
                  font-weight: bold;
                  padding-top: 5px;
              }
      
              .sub-title:not(:first-child) {
                  border-top: 1px solid #ADADAD;
              }
      
              .value {
                  margin-left: 10px;
                  margin-top: 5px;
                  color: #3B3B3B;
                  margin-bottom: 5px;
              }
      
              .tf-tree {
                  width: 100%;
                  height: 100%;
                  overflow: visible;
              }
          </style>
          
      </head>
          
      <body>
          <div class="tf-tree">
              <ul><li>
              <div class="tf-nc">
                  <div class="title">R_DATAFRAME_SCAN </div>
                  <div class="content">
                      <div class="sub-title">Text</div>
                      <div class="value">data.frame</div>
                      <div class="sub-title">Projections</div>
                      <div class="value">x</div>
                      <div class="sub-title">Estimated Cardinality</div>
                      <div class="value">1</div>
                  </div>
          
              </div>
          </li></ul>
          </div>
      
      <script>
      function toggleDisplay(button) {
          const parentLi = button.closest('li');
          const nestedUl = parentLi.querySelector('ul');
          if (nestedUl) {
              const currentDisplay = getComputedStyle(nestedUl).getPropertyValue('display');
              if (currentDisplay === 'none') {
                  nestedUl.classList.toggle('hidden');
                  button.textContent = '-';
              } else {
                  nestedUl.classList.toggle('hidden');
                  button.textContent = '+';
              }
          }
      }
      </script>
      
      </body>
      </html>
          

---

    Code
      writeLines(rel_explain_df(proj, "standard", "graphviz")[[2]])
    Output
      
      digraph G {
          node [shape=box, style=rounded, fontname="Courier New", fontsize=10];
          node_0_0 [label="R_DATAFRAME_SCAN \n───\nText:\ndata.frame\n───\nProjections:\nx\n───\nEstimated Cardinality:\n1"];
      
      }
      	

# Handle zero-length lists (#186)

    Code
      expr_constant(list(integer()))
    Message
      DuckDB Expression: []

# prudence

    Code
      nrow(forbid)
    Condition
      Error:
      ! Materialization is disabled, use `collect()` or `as_tibble()` to materialize.
      ℹ Context: GetQueryResult

---

    Code
      nrow(forbid)
    Condition
      Error:
      ! Materialization is disabled, use `collect()` or `as_tibble()` to materialize.
      ℹ Context: GetQueryResult

---

    Code
      nrow(four_rows)
    Condition
      Error:
      ! Materialization would result in more than 4 rows. Use `collect()` or `as_tibble()` to materialize.
      ℹ Context: GetQueryResult

---

    Code
      nrow(nine_cells)
    Condition
      Error:
      ! Materialization would result in more than 4 rows. Use `collect()` or `as_tibble()` to materialize.
      ℹ Context: GetQueryResult

---

    Code
      nrow(bad_rows)
    Condition
      Error:
      ! Materialization would result in more than 4 rows. Use `collect()` or `as_tibble()` to materialize.
      ℹ Context: GetQueryResult

---

    Code
      nrow(bad_cells)
    Condition
      Error:
      ! Materialization would result in more than 4 rows. Use `collect()` or `as_tibble()` to materialize.
      ℹ Context: GetQueryResult

