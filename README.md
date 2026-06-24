# zipomatic
Render ZIPs from multiple repositories / branches / revisions to see in-progress drafts

**FIXME:** Everything below here is a paste from a zips repo issue comment draft, so where it says "this repo" it means https://github.com/zcash/zips and where it says `zip-previews` repository it means this repository.

Here's a solution I believe is worth prototyping before modifying this repository's toolchain. Then, if this out-of-repo infrastructure proves its usefulness and is reliable, I may propose changing ZIP 0 to recommend it.

### Prototype

The prototype I'm working on is approximately this for MVP v0 - let's call it `zip-previews`, and there's a `zip-previews` public URL and an associate github repository.

#### User Stories

##### ZIP Authors - New ZIPs

Someone who wants to introduce or modify any existing ZIPs creates their own github fork, then they edit existing or new ZIP source files such that they render using the existing rendering toolchain within the ZIPs repo. Then, they push their changes to their own github fork and branch, e.g. `https://github.com/Alice-the-new ZIP-artiste/zips/awesome_new_zip_a`.

They immediately create a new PR, even though their ZIP is far from ready for the attention of ZIP Editors. To signal that they do not expect ZIP Editor attention/bandwidth, they create this as a github "Draft PR" (not to be confused with "Draft" status ZIP documents).

They then submit a PR against `zip-previews` which adds their PR to the `zip-previews` PR whitelist. As soon as the `zip-previews` human+robot maintainers determine that request does not present an unacceptable security risk, the `zip-previews` automation renders the ZIPs in that PR, which, on success, leads to a well-known sub-URL of the `zip-previews` site.

The author of the new ZIP(s) posts to the forum, discord, social media, etc... the URL of the public rendering of their text.

**Key Requirements:**

- Their editing/rendering process is the same whether they're editing their ZIPs branch with no knowledge or use of `zip-previews`. Stated another way, someone who is already familiar with editing ZIPs and rendering them in the current system does not need to alter any of that process, but only needs to add one step (submitting the request to `zip-previews` to include their branch in renderings via a PR against `zip-previews`).
- Their source is rendered to a public URL they can freely share anywhere URLs work.
- Their Github PR is in the "draft" state
  - **Key Dependency / Assumption:** All current users of the ZIPs repository (including ZIP editors) know that any PR in the github "draft" state can be ignored in-so-far as ZIP editing goes.

##### ZIP Authors - Existing ZIPs

Same story as above, except instead of only introducing new ZIPs, they modify existing ZIPs (and also potentially add new ones).

##### Specific Preview ZIP Readers

A reader, Bob the Researcher, interested in a particular preview of one or more new or changed ZIPs discovers the `zip-previews` URL for those changes (perhaps on a forum / social post), and then reads those rendered texts.

He's quite flabbergasted to learn this official looking document specifies replacing the ZEC monetary policy with an outrageous scheme completely contrary to what Bob believes the Zcash community would endorse, so he's thinks "what is going on here?!" and glances at then notices a blurb atop each ZIP document along these lines:

> This is part of a proposed change to the text of one or more ZIPs which has not yet begun the Zcash Improvement Proposal editorial review process. ZIPs which have received sufficient vetting to proceed through that process appear on the official site https://zips.z.cash. This text is available for review comments in https://github.com/zcash/zips/pulls/<NNN> and other discussions may be found throughout the Zcash infosphere.

-so then Bob realizes the text hasn't received any known threshold of scrutiny or review by the Zcash community. Bob then skims zips.z.cash to see which ZIPs are more mature in the review process, then follows the PR link to find someone else has left a review comment expressing his concern.

He finally returns to the original discussion where he was linked to this preview and notices no one has yet discussed that concern, so he posts:

> I was concerned about Foo when I read this, and I noticed there's already [a github comment](https://github... you get the idea) comment to that effect. I was curious if any of you disagree with that criticism, because I'm curious if I've missed something.

**Key Requirements:**

- Each rendered ZIP on the `preview-zips` site has the disclaimer with links visible at the top of the rendered document. (This is the sole delta from the equivalent `zips.z.cash` rendering.)

##### Preview ZIP Explorers

Another researcher, Cherisse, is curious what all of the new ZIPs or in-progress edits are out there, even if some of them haven't received more formal review or scrutiny. She just discovered the `zip-previews` site and loads the main front page. She reads about the purpose of the site and then sees an index of all of the branches it renders.

**Key Requirements:**

- Each branch rendering is available at a unambiguous legible URL.
- The front page describes what the site is.
- The front page includes an index of all renderings.

#### Scope

##### Intentionally / Permanently Out-of-Scope / Alternative Product Goals

- on-site commenting
- on-site voting, reactions
- anything on-site that requires or relies on any concept of user (outside of git revision whitelisting which may implicitly rely on other site access control designs, such as MVP v1's use of PR links)

##### Currently Out of Scope

- rendering or supporting changes to the protocol spec pdfs or latex source or other non-ZIP documents
- non-github forks / repos
- per branch directory tree diffs
- per-doc diffs
- supporting multiple rendering paths/configs different from `nix develop --command make all-zips`
- requiring significant changes to this ZIPs repo's rendering processes outside of the single rendering entry point, or altering any existing flow used by current ZIPs rendering users
- strong security for rendering sandboxing

#### Future Potential Improvements

- support non-github ZIP editors
- support the protocol specification (needs hefty UX considerations)
- index deduplication for unmodified documents, so for example the entry for `alice-the-
