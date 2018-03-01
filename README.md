# How to solve Mercurial / Bitbucket HTTP Error 400: Bad Request
*By Magnus Akselvoll - Ibistic Technologies - 2017-04-24*

## Disclaimer
*The proposed solutions described in this article are dangerous and may render your repository unusable. Please backup and check that your backup can be restored and is working before trying any of this. Run any command suggested here on your own risk. The author is not an expert on the matter nor able to get you out of weird sitionation.*

## The problem
When you do a pull in Mercurial, you get an error message of type "HTTP Error 400: Bad Request". We observed this against Bitbucket, but as explained below, this is an inherit problem with the Mercurial HTTP protocol.

## Cause
When doing a pull over HTTP, the Mercurial client sends a list of all known heads, i.e. all branches with a commit that has not been merged to another branch. Typically what you consider heads are the list of branches you see when you execute `hg branches`. However, this commands, and probably most frontends, hides any branch that has been closed. For the underlying protocol, however, closed branches are still considered heads and will be sent with the pull command.

The mechanism Mercurial uses for sending these heads, is by grouping the hashes of the heads into a set of HTTP headers. However, when there are too many heads in the repository (we observed this with around 1000 heads), the server will respond with the message: **HTTP Error 400: Bad Request**.

## Root cause
There are typically two reasons why you have closed branches that have not been committed in your respository.

The first one is abandoned branches. You start developing a feature, for whatever reason abandon it and close the branch. This is a perfectly normal situation in modern software development.

The second one is less easy to see. It has to do with how you close branches when you merge them. There are two schools here: (a) You merge your branch to e.g. default and then close it. (b) You close your branch and then merge it to e.g. default. If you use style (b) for merging your branches, the commit required to close the branch, will make Mercurial consider the branch a head, i.e. it has commits that have not been merged to another branch. These branches typically add up quickly and are likely to be the main cause of your problem.

## How to diagnose the problem
Run an `hg pull` through e.g. a Fiddler proxy. This solution is described on several web pages. Note that you have a large number of changesets being sent as HTTP headers.

Execute the following HG command to see a list of all your "closed heads": `hg log -r "heads(0:tip) and closed()"`

If this command lists a long list of changesets, you have probably identified the cause.

## Solution - cleanup
**First read the disclaimer in the beginning of the document.**

To get your repository working again, you need to merge all those unwanted heads to some branch. We propose the following:
* Create a branch for the sole purpose of merging unwanted heads. This can be called e.g. ".graveyard". We recommend creating this branch from the first changeset of your repository, however this might not be important.
* For each unwanted branch do the following
  * Update to your .graveyard branch: `hg update --clean --rev .graveyard`
  * Merge the branch into your .graveyard branch: `hg merge --rev SOME_CHANGESET --tool :local`
  * Revert all the changes to your .graveyard branch: `hg revert --all --rev .graveyard`
  * Commit your changes: `hg commit --message "Eliminating closed head SOME_CHANGESET by merging to .graveyard"`
* If everything seems correct, push your changes to the central repository: `hg push`

To ease the work of performing the above action foreach branch, we have developed some Powershell scripts found in this repository. Their description and usage is as follows.

### CommonHGFunctions.ps1
Required for the other two scripts. Must be placed in the same folder.

### Get-HGClosedHeads.ps1
Can be used stand alone to view the currently closed heads, and is also required by the other script. Usage:

`.\Get-HGClosedHeads.ps1 REPOSITORY_PATH`

Where RESPOSITORY_PATH is the path to the root of your local mercurial repository. For advanced usage, run `.\Get-HGClosedHeads.ps1 -?`

### Merge-HGClosedHeads.ps1
Used to merge up to a given number of closed heads automatically (oldest first). Usage:

`.\Merge-HGClosedHeads.ps1 REPOSITORY_PATH -maxHeadsToClose HEADS_TO_CLOSE`

Where RESPOSITORY_PATH is the path to the root of your local mercurial repository and HEADS_TO_CLOSE is the max number of heads you want to close in one operation. It is recommended to start with HEADS_TO_CLOSE set to 1 and inspect the results before increasing. The script has been tested with batches up to 500 heads in one operation.

For advance usage, run `.\Merge-HGClosedHeads.ps1 -?`

## Solution - long term
To avoid this problem in the future we recommend:
* Close branches before you merge them to other branches
* Either immediately merge any abandoned branches to your .graveyard branch by using the methods described above, or peridically use the scripts presented in this article.

# Links and references
* The problem is well described here: <http://barahilia.github.io/blog/computers/2014/10/09/hg-pull-via-http-fails-400.html>
* This issue at Bitbucket recognizes the problem: <https://bitbucket.org/site/master/issues/8263/http-400-bad-request-error-when-pulling>
* These are the official recmomendations from Mercurial on how to prune branches: <https://www.mercurial-scm.org/wiki/PruningDeadBranches>
* Advanced Mercurial debugging: <https://medium.com/@demianbrecht/advanced-mercurial-debugging-58d80b5305b2>
