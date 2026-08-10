# Edge Properties, Metrology, and Labeled Property Graphs

## 1. The Limitations of Pure RDF Triples in Enterprise Analytics

Resource Description Framework (RDF) represents knowledge strictly as atomic 3-tuples:

$$\langle \text{Subject}, \text{Predicate}, \text{Object} \rangle$$

While mathematically elegant, standard RDF creates severe impedance mismatches when modeling real-world scientific and industrial measurements that require:
1. **Metrology:** Units of measurement (e.g., $mg/mL$, $^{\circ}\text{C}$, $kPa$).
2. **Provenance & Epistemic Confidence:** Extraction confidence scores ($0.0 \dots 1.0$), source page numbers, and bounding-box coordinates.
3. **SKOS Taxonomy Mapping:** Alignment predicates (`skos:exactMatch`, `skos:closeMatch`, `skos:broadMatch`) with associated similarity metrics.

---

## 2. RDF Reification vs. Labeled Property Graphs (LPG)

### The Reification Explosion
To attach a confidence score and unit of measurement to a simple fact like *"Bioreactor-1 operates at 37°C"* in standard RDF 1.1, one must reify the statement:

```turtle
# RDF Reification (5 triples for 1 assertion)
:stmt1 rdf:type rdf:Statement .
:stmt1 rdf:subject :Bioreactor_1 .
:stmt1 rdf:predicate :operatesAtTemperature .
:stmt1 rdf:object "37"^^xsd:decimal .
:stmt1 :unit "degree_Celsius" .
:stmt1 :confidenceScore "0.98"^^xsd:decimal .
```

This causes a **$5\times$ explosion in graph node count**, degrading analytical query performance across distributed data warehouses.

### The Labeled Property Graph (LPG) Solution
In a **Labeled Property Graph (LPG)**, edges are first-class citizen entities that support key-value attribute maps directly:

```
(:Bioreactor {id: 'BR-101'})
       │
       ▼ [CONNECTS {
            predicate: 'operatesAtTemperature',
            value: 37.0,
            unit: 'Celsius',
            confidence: 0.98,
            source_file: 'batch_report_04.pdf',
            page: 12
          }]
       │
       ▼
(:OperatingParameter {name: 'Temperature'})
```

---

## 3. BigQuery ISO GQL Property Graph Implementation

We declare our unified enterprise knowledge graph using BigQuery's native ISO GQL standard (`CREATE OR REPLACE PROPERTY GRAPH`):

```sql
CREATE OR REPLACE PROPERTY GRAPH ${self()}
  NODE TABLES (
    ${ref("global_nodes")} AS global_nodes KEY(node_id),
    ${ref("document_master_record")} AS document_master_record KEY(file_id),
    ${ref("node_aliases")} AS node_aliases KEY(node_id) LABEL Alias
  )
  EDGE TABLES (
    ${ref("global_edges")} AS global_edges KEY(edge_id)
      SOURCE KEY(source_node_id) REFERENCES global_nodes(node_id)
      DESTINATION KEY(target_node_id) REFERENCES global_nodes(node_id)
      LABEL CONNECTS 
      PROPERTIES (
        relationship_type,
        evidence_insight,
        confidence_score,
        unit_of_measure,
        metrology_standard
      ),
    ${ref("edge_close_match")} AS edge_close_match KEY(edge_id)
      SOURCE KEY(source_node_id) REFERENCES node_aliases(node_id)
      DESTINATION KEY(target_node_id) REFERENCES global_nodes(node_id)
      LABEL closeMatch 
      PROPERTIES (relationship_type, similarity_metric)
  );
```

### Analytical Advantages:
1. **Zero Node Bloat:** Nodes represent true domain entities; metadata lives on edges.
2. **Sub-Second Path Traversal:** Graph pattern matching (`MATCH (a)-[e:CONNECTS]->(b) WHERE e.confidence_score > 0.9`) executes without joining auxiliary reification tables.
3. **Seamless SKOS Mapping:** Aliases and cross-ontology synonym mappings live in dedicated lightweight edge tables (`edge_close_match`).
