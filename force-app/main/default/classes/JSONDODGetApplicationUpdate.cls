public class JSONDODGetApplicationUpdate {
	public class Program {
		public String id ; 
		public String name ; 

		
	}
	
	public class ConsolidatedRegulars {

		
	}
	
    
	public Data data ; 

	
	
	public class Address {
		public String city ; 
		public String country ; 
		public String postalCode ; 
		public String addressLine ; 

		
	}
	
	public class Finance {
		public Integer financeAmount ; 
		public Integer numberOfMonths ; 
		public String purchaseOption ; 
		public String paymentFrequency ; 
		public String paymentTiming ; 

		
	}
	
	public class Payments {
		public Rentals rentals ; 

	}
	
	public class FinancialProduct {
		public Program program ; 
		public String id ; 

		
	}
	
	public class Data {
		public String id ; 
		public String status ; 
		public String creationDate ; 
		public List<String> notes ; 
		public List<Proposals> proposals ; 
		public Lessee lessee ; 

		
	}
	
	public class Proposals {
		public String type ; 
		public String assetsLink ; 
		public Boolean isPreferred ; 
		public String id ; 
		public FinancialProduct financialProduct ; 
		public Finance finance ; 
		public Payments payments ; 

		
	}
	
	public class Sic {
		public String name ; 
		public String code ; 

		
	}
	
	public class Lessee {
		public String countryOfRegistration ; 
		public String name ; 
		public String legalName ; 
		public List<Object> dbaName ; 
		public PrimaryPhoneNumber primaryPhoneNumber ; 
		public Business business ; 
		public Address address ; 

		
	}
	
	public class Rentals {
		public List<ConsolidatedRegulars> consolidatedRegulars ; 

	}
	
	public class PrimaryPhoneNumber {
		public String number_Z ; // in json: number

		
	}
	
	public class Business {
		public Sic sic ; 
		public Sic naics ; 

		
	}
        public static JSONDODGetApplicationUpdate parse(String json) {
        return (JSONDODGetApplicationUpdate) System.JSON.deserialize(json, JSONDODGetApplicationUpdate.class);
    }
	
}