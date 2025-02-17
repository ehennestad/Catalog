# Catalog
<h4 align="center">A catalog datatype for MATLAB - A catalog is a collection of unique, named and ordered items.</h4>

<h4 align="center">
  <a href="https://github.com/ehennestad/Catalog/releases/latest">
    <img src="https://img.shields.io/github/v/release/ehennestad/Catalog?label=version" alt="Version">
  </a>
  <a href="https://se.mathworks.com/matlabcentral/fileexchange/158241-catalog">
    <img src="https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg" alt="View Catalog on File Exchange">
  </a>  
  <a href="https://codecov.io/gh/ehennestad/Catalog" > 
   <img src="https://codecov.io/gh/ehennestad/Catalog/graph/badge.svg?token=70NVCM2K77" alt="Codecov"/> 
  </a>
  <a href="https://github.com/ehennestad/Catalog/actions/workflows/run_tests.yml/badge.svg?branch=main">
   <img src="https://github.com/ehennestad/Catalog/actions/workflows/run_tests.yml/badge.svg?branch=main" alt="Run tests">
  </a>
  <a href="https://github.com/ehennestad/Catalog/security/code-scanning">
   <img src=".github/badges/code_issues.svg" alt="MATLAB Code Issues">
  </a>
</h4>

## Class Description

This class is something of a hybrid between a dictionary and a table. The main idea is that it will hold unique items, where an item is a structure or an object with a set of fields (properties).

### Key Differences from a Table with Row Entries:

- All items should be named (items can be renamed).
- All items will have a universal unique identifier (uuid) which should never change.
- Items are ordered (and reorderable), and items can be retrieved by their row number.

## Installation
Install from MATLAB's Addon Manager or clone this repository.
