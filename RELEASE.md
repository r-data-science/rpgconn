# Release Checklist

## 1. Sync Versioning and Notes

- Update `DESCRIPTION` version.
- Add/update `NEWS.md` entry for the release.
- Update `cran-comments.md` for current submission context.

## 2. Run Full Validation Gate

```r
devtools::document()
devtools::test()
devtools::check()
devtools::spell_check()
urlchecker::url_check(".")
```

If Quarto throws `attempt to write a readonly database` while rendering vignettes, run check with a writable cache:

```r
withr::with_envvar(c(XDG_CACHE_HOME = tempdir()), devtools::check())
```

## 3. Validate Website/Docs

```r
pkgdown::build_site()
```

Confirm:
- all vignettes render (`.qmd`)
- no stale argument names in docs
- examples match current API

## 4. Optional Integration Confidence

Run local Postgres E2E test:

```bash
export RPGCONN_RUN_DB_TESTS=true
export RPGCONN_TEST_CONN_STRING="postgresql://postgres:postgres@localhost:5432/postgres"
```

Then:

```r
devtools::test()
```

## 5. CRAN + GitHub Release

- Submit to CRAN.
- Create GitHub release with highlights from `NEWS.md`.
- Confirm pkgdown workflow deploys updated website.
