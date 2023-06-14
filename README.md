# DataDash Wallet

DataDash wallet using an ERC-20 smart contract.

## Project Structure

According to our project, there everything is divided on three things: data, domain, presentation. 

In data we have everything related to working with data. HttpClients, Databases, Sockets. 
In data we have repositories - they should work with data-objects (httpclient / serialized data) inside, but expose logic on domain language.
For example, the repository method definition can look like this - Book getBook(int bookNumber). The method definition say to us that method will return book according to book number. There is no everything HTTP-related or Database-related in method signature. So according to method definition we can't say what data source will be used (rest api / protobuf* api / db). This give us an option to change implementation of  method, without changing code that actually uses this method. Now we are doing HTTP requests to get the book, tomorrow backend can say "Hey, now we use Protobuf api instead of http api", in a week we will store the books locally and we will change the method implementation again, but not the signature, so we don't need to change the methods which actually use this getBook method, we will need to only change data layer, not others domain or presentation layer.
colors come from defination of designer's Figma. The logic part is to call the related APIs.

The repository: https://github.com/MXCzkEVM/mxc-shared-flutter

## Figma

The link: https://www.figma.com/file/dFx4fIwI2aiKFGWLDL3Qjv/Untitled?type=design&node-id=0-1&t=neu0ndJvK4jxa7Qj-0
