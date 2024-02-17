- trying to use docker network bridge so django container can network to docker host to connect to postgres
- https://stackoverflow.com/questions/24319662/from-inside-of-a-docker-container-how-do-i-connect-to-the-localhost-of-the-mach

[x] when migrations fail, the prestart task isn't exiting with a non-zero exit code
[x] does this work when publishing an update?

Please confirm the following if submitting a new pack:

## New Pack Checklist
- [x] The README includes any information necessary to run the application that is not encoded in the pack itself.
- [x] The pack renders properly with `nomad-pack render <NAME>`
- [x] The pack plans properly with `nomad-pack plan <NAME>`
- [x] The pack runs properly with `nomad-pack runs <NAME>`
- [x] If applicable, a screenshot of the running application is attached to the PR.
  - expect the django app to be available at the address of the allocation/client
  - if following the `Trying This Pack` instructions in `README.md` then the endpoint at `address:port/` should respond w/ `200 Ok` 
- [x] The default variable values result in a syntactically valid pack.
- [x] Non-default variables values have been tested. Conditional code paths in the template have been tested, and confirmed to render/plan properly.
- [x] If applicable, the pack includes constraints necessary to run the pack safely (I.E. a linux-only constraint for applications that require linux).
  - N/A