Balihoo DAM Client
==================

This package provides a simple SDK for managing assets in the Balihoo Digital Asset Manager (DAM).  The dam lives within the Form-Builder, and allows clients using local tools (such as [balihoo-creative](https://github.com/balihoo/balihoo-creative) to upload assets needed for creatives to be hosted, indexed and searchable for use in those creatives.
  
Node and Browser versions
---
This package contains two versions of the tool which have mostly the same exposed methods.  Node may require this file and call the below functions on the result.  The browser version should be included in a web page, which will then register itself as the variable window.balihoo_dam_client.  Both methods should have the same basic methods available, with the main difference being that node will pass a filename, while the browser should pass a browser File object, such as that obtained by `document.getElementById('myFileInputId').files[0]`

For node, see [test/full.integration.coffee](test/full.integration.coffee) for examples.
For the browser, see [test/browser-test.html](test/browser-test.html)

Main SDK Methods
---
* config(object)

The sdk needs certain configurations to function.  These can be provided by a local file called config.js, or by calling this method.
Both config options should supply the same object, although the file will use node exports, while the object will be a plain JS object.
The object should contain:

    {
      formbuilder: {
        url: <url to formbuilder>
      }
    }
    
In the browser, instead set `window.balihoo_dam_client.fburl` to the correct url;

* uploadFile(File|filename, [authorizeUploadResponse,] callback)

Upload a file referenced by the filename.  Obtaining authorization ahead of time is optional, if omitted it will be fetched prior to upload.

File - the browser File object or...
filename - the path to the file on disk
callback - a function(error, response)  
error will exist if the file failed to upload for any reason.  This reason might be related to the connection, s3 parameter validation, the file already existing, the form builder failing to register the file, etc.
response will be an object containing the assetid of the file, the url, and some other meta data.



Other SDK Methods
---
These may not be necessary, but are available if needed.

* authorizeUploadHash(hash, callback)

This function can pre-authorize an upload.  It is useful to find a file's meta data without uploading it if it doesn't exist.

hash - the MD5 hash of the file to authorize

callback - a function(error, authorization)  
error will contain any connetion or request errors, such as missing parameters.  
authorization will be an object that always contains a fileExists key.  If fileExists is true, the dam already contains that file and upload may be skipped.  Other fields in the object will be the previously saved values for this object.  If fileExists is false, the object will contain other fields that need to be passed to uploadFile.

* authorizeUploadFilename(filename, callback)
* authorizeUploadFile(File, callback)

Same as authorizeUploadHash, but reference a File|filename instead of a file hash.

* calculateFileMD5(File|filename, callback)

Just calculate the md5sum of the file
