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


# TODO

* Better Handling of images (attached or not)
