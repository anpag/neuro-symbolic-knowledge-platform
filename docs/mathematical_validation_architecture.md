# Mathematical Validation & Relational SHACL Architecture

## 1. Executive Summary
In high-stakes enterprise domains (e.g., pharmaceutical CMC, aerospace, regulatory compliance), standard generative AI extraction pipelines fail due to non-deterministic hallucinations. While Large Language Models excel at semantic extraction from ambiguous natural language, they cannot be trusted to self-police their own output against formal ontological axioms.

The **Neuro-Symbolic Knowledge Platform** decouples extraction from validation:
1. **Extraction (Stochastic):** Generative AI agents extract candidate assertions without schema gating.
2. **Validation (Deterministic):** BigQuery executes relational set joins against a pre-materialized **Meta-Graph**, enforcing SHACL topological constraints with 100% mathematical precision.

---

## 2. Theoretical Framing: Relational SHACL

In standard Semantic Web architectures, SHACL (Shapes Constraint Language) is evaluated using recursive graph traversal engines (e.g., TopBraid, Apache Jena). At enterprise scale (millions of triples), these engines exhibit $O(N^k)$ computational complexity.

We transform SHACL validation into **Relational Set Operations** executed natively in distributed SQL databases (BigQuery).

### Rule 1: Vocabulary & Class Verification (Node Check)
Every extracted entity node must belong to a recognized concept class in the ontology TBox:

$$\text{ValidNodes} = \{ n \in \text{ExtractedNodes} \mid \exists c \in \text{OntologyClasses} \text{ s.t. } \text{LOWER}(n.class) = \text{LOWER}(c.label) \}$$

In Dataform SQLX:
```sql
SELECT
  un.file_id,
  un.entity_name,
  un.raw_ontology_class,
  (nc.label IS NOT NULL) AS is_valid_class
FROM unnested_nodes un
LEFT JOIN ${ref("onto_classes")} nc
  ON LOWER(TRIM(un.raw_ontology_class)) = LOWER(TRIM(nc.label));
```

### Rule 2: Topological & Axiomatic Verification (Edge Check)
Every extracted relationship edge $(s, p, o)$ must satisfy the domain and range constraints defined in the ontology RBox:

$$\text{Domain}(p) \sqsubseteq \text{Class}(s) \quad \land \quad \text{Range}(p) \sqsubseteq \text{Class}(o)$$

Rather than computing subsumption hierarchies at query time, the hierarchy is pre-expanded by our offline reasoning engine into the **Meta-Graph** table `onto_rules`:

```sql
SELECT
  re.edge_id,
  re.source_node_id,
  re.target_node_id,
  re.relationship_type,
  (meta.rule_id IS NOT NULL) AS is_topologically_valid
FROM raw_edges re
INNER JOIN valid_nodes s ON re.source_node_id = s.node_id
INNER JOIN valid_nodes o ON re.target_node_id = o.node_id
LEFT JOIN ${ref("onto_rules")} meta
  ON LOWER(TRIM(re.relationship_type)) = LOWER(TRIM(meta.predicate))
  AND LOWER(TRIM(s.ontology_class)) = LOWER(TRIM(meta.domain_class))
  AND LOWER(TRIM(o.ontology_class)) = LOWER(TRIM(meta.range_class));
```

---

## 3. Dead-Letter Queues (DLQ) & Active Learning

Violations are not discarded; they are segregated into two distinct analytical streams:
1. **`dlq_semantic_failures`:** Syntactic errors, hallucinated property names, or ungroundable entity classes.
2. **`unbound_insights`:** Topologically novel relationships extracted with high LLM confidence that do not yet exist in the formal ontology. These feed into human-in-the-loop ontology engineering workflows for continuous schema enrichment.
