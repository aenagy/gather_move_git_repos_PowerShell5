# Move-LocalGitRepositories
Finds and moves GitHub repos in local file system and moves them to a single folder tree.

## Introduction

I had git repositories scattered in different folders and needed to consolicate them into a single folder tree.

## Usage

Developed and tested on Windows 10 using PowerShell 7 for the command-line.

Note that this script will look for the 'url' parameter in the 'config' file in the hidden '.git' folder of each repository. The url is used to determine the folder path structure under the 'destinationFolder' using the format:

  `destinationFolder\<Git FQDN from url>\<Git username from url>\<Git repo name from source folder>`

The actual folder move is done with:

  `Move-Item -LiteralPath $moveSourceFolder -Destination $moveDestinationFolder`

The result is that the final folder in the destination is the exact same as in the original source folder path and therefore might not match the repo name from the `url` parameter in the `config` file. The alternative would be to use the repo name from  the `url` parameter but then iterate over all files and folders from the source folder and move them individually. This is a small code change but the approach I took would be faster, assuming that the source and destination folders are on the same NTFS volume, as the entire folder is moved.

## Execution

These examples asume the above PowerShell session.

### Move multiple git repositories in local file system to single folder tree for consolidation.

This example also include the optional '-ignoreFolders'. sourceFolders is defined as an array of [string] but will accept a single string (its automatically converted to [string[]]).

`Move-LocalGitRepos.ps1 -sourceFolders @( "D:\Data\" ) -destinationFolder "D:\Data\Projects\Programming\git" -ignoreFolders @( "D:\Data\Projects\ingnoreThisFolder" , "D:\Data\test2" )`

## Author

Andrew Nagy

https://www.linkedin.com/in/andrew-e-nagy/
