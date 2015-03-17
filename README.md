Balihoo DAM Client
==================

This package provides a simple SDK for managing assets in the Balihoo Digital Asset Manager (DAM).  The dam lives within the Form-Builder, and allows clients using local tools (such as [balihoo-creative](https://github.com/balihoo/balihoo-creative) to upload assets needed for creatives to be hosted, indexed and searchable for use in those creatives.
  
Using the tool will require credentials to the form builder.  See config.js.default and substitute in your values.


SDK Methods
---

* authorizeUploadHash(hash, callback)

This function can pre-authorize an upload.  It is useful to find a file's meta data without uploading it if it doesn't exist.

hash - the MD5 hash of the file to authorize

callback - a function(error, authorization)  
error will contain any connetion or request errors, such as missing parameters.  
authorization will be an object that always contains a fileExists key.  If fileExists is true, the dam already contains that file and upload may be skipped.  Other fields in the object will be the previously saved values for this object.  If fileExists is false, the object will contain other fields that need to be passed to uploadFile.

* authorizeUploadFilename(filename, callback)

Same as authorizeUploadHash, but reference a filename instead of a file hash.

* uploadFile(filename, [authorizeUploadResponse,] callback)

Upload a file referenced by the filename.  Obtaining authorization ahead of time is optional, if omitted it will be fetched prior to upload.

filename - the path to the file on disk  
callback - a function(error, response)  
error will exist if the file failed to upload for any reason.  This reason might be related to the connection, s3 parameter validation, the file already existing, the form builder failing to register the file, etc.
response will be an object containing the assetid of the file, the url, and some other meta data.



