# Data Licences and Attribution

Calori's bundled food database (`assets/db/foods.sqlite`) is compiled from several
public food composition tables. This file records what each contributes, under what
terms, and the exact attribution each licence requires.

The in-app **Sources** screen renders the same information from the `meta` table of
the shipped database, so it always reflects what actually built — see
[03-food-data.md](03-food-data.md).

Retrieval dates are stamped by `tools/build_foods_db/manifest.py` at build time and
mirrored here whenever the database is rebuilt.

---

## Bundled sources

### USDA FoodData Central — SR Legacy, Foundation Foods, FNDDS (Survey)

- **Publisher:** U.S. Department of Agriculture, Agricultural Research Service
- **URL:** https://fdc.nal.usda.gov/download-datasets/
- **Licence:** Public domain (U.S. Government work). Effectively CC0.
- **Obligation:** None. Attribution is requested as a courtesy, not required.
- **Attribution used:**
  > U.S. Department of Agriculture, Agricultural Research Service. FoodData Central.
- **Retrieved:** _stamped at build_

### CoFID — McCance and Widdowson's The Composition of Foods Integrated Dataset

- **Publisher:** Office for Health Improvement and Disparities (formerly Public Health England), UK
- **URL:** https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid
- **Licence:** **Open Government Licence v3.0**
- **Obligation:** Attribution required. Commercial use permitted.
- **Attribution used:**
  > Contains public sector information licensed under the Open Government Licence v3.0.
  > McCance and Widdowson's The Composition of Foods Integrated Dataset (CoFID), 2021.
- **Retrieved:** _stamped at build_

### CIQUAL — French food composition table

- **Publisher:** ANSES (Agence nationale de sécurité sanitaire de l'alimentation, de
  l'environnement et du travail)
- **URL:** https://ciqual.anses.fr/
- **Licence:** **Licence Ouverte / Open Licence (Etalab)**
- **Obligation:** Attribution required, naming the source and the version date.
  Commercial use permitted.
- **Attribution used:**
  > ANSES-CIQUAL food composition table. © ANSES, licensed under the Open Licence (Etalab).
- **Retrieved:** _stamped at build_

### Canadian Nutrient File (CNF)

- **Publisher:** Health Canada
- **URL:** https://open.canada.ca/data/en/dataset/1b6139bd-ed7e-4043-bc28-ff00e10f3109
- **Licence:** **Open Government Licence – Canada**
- **Obligation:** Attribution required. Commercial use permitted.
- **Attribution used:**
  > Contains information licensed under the Open Government Licence – Canada.
  > Canadian Nutrient File, Health Canada.
- **Retrieved:** _stamped at build_

### Frida — Danish Food Composition Database

- **Publisher:** DTU Fødevareinstituttet (National Food Institute, Technical University of Denmark)
- **URL:** https://frida.fooddata.dk/
- **Licence:** Published free of charge; **credit is mandatory on each display or use of the
  data**. No formal open-licence identifier is asserted by the publisher.
- **Obligation:** Attribution required on display. Treated conservatively as attribution-only.
- **Attribution used:**
  > Frida, Danish Food Composition Database, DTU National Food Institute (frida.fooddata.dk).
- **Retrieved:** _stamped at build_

### INDB — Indian Nutrient Databank

- **Publisher:** Compiled by the INDB authors from ICMR-NIN's Indian Food Composition
  Table (IFCT) 2017 and 2004.
- **URL:** https://github.com/lindsayjaacks/Indian-Nutrient-Databank-INDB-
- **Paper:** *Current Developments in Nutrition* (2024), open access.
- **Licence:** **The repository carries no LICENSE file.** No explicit redistribution grant
  has been located. The open-access licence on the paper does not license the dataset, and
  the underlying IFCT data must be requested separately from ICMR-NIN.
- **Status:** Included by project decision, with attribution, pending written permission
  from the authors. The build adapter (`tools/build_foods_db/sources/indb.py`) is isolated
  so this source can be removed with one file change and a rebuild.
- **Attribution used:**
  > Indian Nutrient Databank (INDB), derived from ICMR-NIN Indian Food Composition Tables.
  > See github.com/lindsayjaacks/Indian-Nutrient-Databank-INDB-
- **Retrieved:** _stamped at build_

### Food Composition Table for Pakistan (revised 2001)

- **Publisher:** Government of Pakistan / UNICEF; hosted by FAO
- **URL:** https://www.fao.org/fileadmin/templates/food_composition/documents/regional/Book_Food_Composition_Table_for_Pakistan_.pdf
- **Licence:** FAO-hosted publication. Terms to be confirmed before shipping this source.
- **Obligation:** Attribution. **Verify FAO's reuse terms before including in a release build.**
- **Attribution used:**
  > Food Composition Table for Pakistan (revised 2001).
- **Retrieved:** _stamped at build_

---

## Deliberately excluded

These are excluded to keep `foods.sqlite` free of share-alike obligations, so the built
database can be reused without inheriting a copyleft licence.

| Source | Licence | Why excluded |
|---|---|---|
| Australian Food Composition Database (AFCD) | CC BY-SA 3.0 AU | **Share-alike** on derivative databases |
| Open Food Facts | ODbL 1.0 (contents: DbCL; images: CC BY-SA) | **Share-alike** on derivative databases |
| USDA Branded Foods | CC0 | 2.9 GB; manufacturer-submitted and inconsistent; only useful with a barcode scanner |
| `ifct2017` | AGPL-3.0 since April 2025 | AGPL is unsuitable for a distributed mobile app |

If a share-alike pack is shipped later (`foods_ext.sqlite`), it will be distributed
separately under ODbL with its own notice, and will not be merged into `foods.sqlite`.

---

## Energy unit note

IFCT 2017 reports energy in **kJ**; IFCT 2004 reported kcal. The builder converts with
the FAO factor **kcal = kJ / 4.184** and fails the build on any row exceeding 900 kcal per
100 g, which is the signature of an unconverted kJ value.
