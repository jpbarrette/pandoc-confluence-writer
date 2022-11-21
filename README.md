# Installation

Just download the file JATS.lua and put it in a convenient location. Pandoc includes a lua interpreter, so lua need not be installed separately. You need at least Pandoc version 1.13, released August 2014 (this release adds --template support for custom writers).

# Usage

To convert the markdown file example1.md into the JATS XML file example1.xml, use the following command:

`$ pandoc -v`

then copy wiki.put the file in that directory\templates\default.confluence.lua


### NOTES

Look at https://github.com/mfenner/pandoc-jats/blob/master/sample.lua (footnotes)


https://github.com/jgm/pandoc/blob/master/data/pandoc.lua


In fact, put in into confluence storage format!

https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html#ConfluenceStorageFormat-Lists

(start from sample.lua)

https://stackoverflow.com/questions/6345948/css-for-specific-text-on-confluence


https://docs.atlassian.com/confluence/REST/latest-server/#content/{id}/child/attachment-createAttachments
https://www.emacswiki.org/emacs/ConfluenceMode

# TODO

* Better Handling of images (attached or not)
* Trying to fix footnotes's link which is after a paragraph annotation (link is one line down).
* Adding configurable CSS stylesheet
* SingleQuoted is missing

# CSS for image caption

https://bitbucket.org/ryanackley/confluence-image-captions/wiki/Home
