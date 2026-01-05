## Unreleased

## 0.23.1

- fix(tlsroute): fix example hosts format

## 0.23.0

- feat: added extraLabels on relevant services, fixing #123

## 0.22.2

- fix: add snapshotAgent security context to snapshot agent

## 0.22.1

- fix: add snapshotAgent resources to the templating, fixing #121

## 0.22.0

- feat: added [openbao-snapshot-agent](https://github.com/openbao/openbao-snapshot-agent) as cronjob to chart

## 0.21.2

- fix: Fix removed whitespace for extraObjects by @javex in https://github.com/openbao/openbao-helm/pull/114

## 0.21.1

- fix: do not produce empty annotations and consolidate general annotation handling in helpers file

## 0.21.0

- feat: add support for gateway-api tlsroutes

## 0.20.0

### Changes

- Set default value for podManagementPolicy to 'OrderedReady'

## 0.19.3

### Changes

- Update default image to `2.4.4`

## 0.19.2

### Changes

- fix(grafana): dashboard datasource by @CorentinPtrl

## 0.19.1

### Changes

- Security update to `2.4.3`

### Docs:

- Reintroduce `CHANGELOG.md`

## 0.19.0

### Changes

- chore: run helm-docs by @pree in https://github.com/openbao/openbao-helm/pull/95
- docs(values): clean up and improve values.yaml documentation by @kangetsu121 in https://github.com/openbao/openbao-helm/pull/96
- ci: allow pipeline to skip chart bump and release (#97) by @kangetsu121 in https://github.com/openbao/openbao-helm/pull/98
- feat: adding extraObjects to enable extra kubernetes manifest deployment by @venkatamutyala in https://github.com/openbao/openbao-helm/pull/99

**Full Changelog**: https://github.com/openbao/openbao-helm/compare/openbao-0.18.4...openbao-0.19.0

## 0.18.4

### Changes

- fix: namespace on mutatingwebhook by @swallimann-dinum in https://github.com/openbao/openbao-helm/pull/94

**Full Changelog**: https://github.com/openbao/openbao-helm/compare/openbao-0.18.3...openbao-0.18.4

## 0.18.3

### Changes

- fix: missing namespace by @swallimann-dinum in https://github.com/openbao/openbao-helm/pull/93

**Full Changelog**: https://github.com/openbao/openbao-helm/compare/openbao-0.18.2...openbao-0.18.3

## 0.18.2

### Changes

- feat(server): add configurable podManagementPolicy parameter by @azalio in https://github.com/openbao/openbao-helm/pull/90

**Full Changelog**: https://github.com/openbao/openbao-helm/compare/openbao-0.18.1...openbao-0.18.2

## 0.18.1

### Changes

- Add OCM artifact for OpenBao by @voigt in https://github.com/openbao/openbao-helm/pull/75
- chore(openbao): upgrade to 2.4.1 by @pree in https://github.com/openbao/openbao-helm/pull/87
- fix(ocm): use correct file extension for workflow by @pree in https://github.com/openbao/openbao-helm/pull/88
- fix(workflow/release): add `workflow_dispatch` to allow triggering manual releases by @pree in https://github.com/openbao/openbao-helm/pull/89
- give ocm job package write permissions by @phyrog in https://github.com/openbao/openbao-helm/pull/91

**Full Changelog**: https://github.com/openbao/openbao-helm/compare/openbao-0.18.0...openbao-0.18.1

## 0.18.0

### Changes

- chore(openbao-csi): bump to version 2.0.0 by @eyenx in https://github.com/openbao/openbao-helm/pull/86

**Full Changelog**: https://github.com/openbao/openbao-helm/compare/openbao-0.17.1...openbao-0.18.0
