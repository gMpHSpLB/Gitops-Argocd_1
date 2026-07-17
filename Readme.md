GitOps ArgoCD Repository 
The Git generator to discover environments by directory presence rather than needing a manifest per env.

This env-config.yaml pattern is deliberate: rather than encoding environment-specific policy (auto-sync? self-heal? who gets paged?) inside the ApplicationSet template as conditionals, you push it into data the Git generator reads. The template stays generic; the data varies. This is the single biggest maintainability win ApplicationSets offer over hand-written Applications.
