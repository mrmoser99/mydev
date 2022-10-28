/**
 * Test class for creating Product test data 
 * 
 * Version 1.0
 * 
 */
@isTest
public class TestProductBuilder {
    
    private String name = 'Tractor Product';
    private String family = 'Asset Soft';
    private String currencyIsoCode = 'USD';
    private Id regionId;
    private Boolean insertRecord = false;

    public TestProductBuilder withName(String name) {
        this.name = name;
        return this;
    }

    public TestProductBuilder withFamily(String family) {
        this.family = family;
        return this;
    }

    public TestProductBuilder withRegion(Id regionId) {
        this.regionId = regionId;
        return this;
    }

    public TestProductBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }
    
   
    public Product2 build() {
        Product2 product = new Product2(
            Name = this.name,
            Family = this.family,
            CurrencyIsoCode = this.currencyIsoCode,
            IsActive = true
        );

        if(insertRecord) {
            insert product;
        }

        return product;
    }
}