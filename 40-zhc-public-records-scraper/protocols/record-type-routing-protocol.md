# Record-Type Routing Protocol (Skill 40)

Maps a real-estate question to the right `--record-type` so the router queries
the correct portal/search within a county.

## Mapping
| Question / use case | `--record-type` | Portal class |
|---|---|---|
| Who owns this? assessed value? beds/baths? | `assessor` | assessor / property-appraiser / appraisal |
| Deeds, mortgages, liens, NOD, lis pendens | `recorder` | recorder / official-records / grantor-grantee |
| Comparable sales / sale history | `assessor` (sales) | assessor + recorder |
| Tax bill / tax delinquency | `tax` | tax / treasurer |
| Parcel map / GIS / boundaries | `parcel` | parcel / GIS |
| Building permits | `permits` | assessor or building-dept (often Tier 3) |

## How the agent uses it
1. Classify the question → pick a `--record-type`.
2. Run `02-detect-and-route.sh --address "<addr>" --record-type <type>`.
3. Execute the emitted plan LIVE (or use the cached plan on a cache hit).
4. On Tier 4, honest-gap.

## Notes
- A county's portal may expose several record types on different domains; the
  Tier 1 registry lists the record types each county portal covers.
- `permits` frequently has NO unified county portal → expect Tier 3 (operator
  config) or Tier 4 (honest gap) for many jurisdictions. That is honest, not a
  failure.
