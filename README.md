# Package Tracking

This is a Ruby web scraper app.

To scrape the example website included in the code:
```
target = Crawler.new
target.process

```



This should result in:

```
"Bill due date: 12/2/12"
"Bill amount: $125"
"Usage (kWh): 145"
"Service end date"
"Usage History"
```
### Setup
```
gem install mechanize
gem install mocha

Make sure to include username and password in the yml file

```
## Running the tests

```
ruby page_test.rb
```

