public class JSONDODGetAssetsUpdate {

	public class Pagination {
		public Integer page;
		public Integer pageSize;
		public Integer itemCount;
		public Integer pageCount;
		public Links links;
	}

	public List<Data> data;
	public Pagination pagination;

	public class Address {
		public String addressType;
		public String addressLine;
		public String city;
		public String postalCode;
		public String country;
		public String region;
		public String county;
	}

	public class Finance {
		public Integer quantity;
		public Integer salePrice;
		public OtherCosts otherCosts;
	}

	public class Links {
		public String self;
		public String first;
		public String next;
		public String prev;
		public String last;
	}

	public class Data {
		public String id1;
		public Catalog catalog;
		public Finance finance;
		public String condition;
		public Address address;
	}

	public class Structure {
		public String masterType;
		public String category;
		public String type;
		public String brand;
		public String model;
	}

	public class Identifiers {
		public Structure structure;
	}

	public class Catalog {
		public String id2;
		public Identifiers identifiers;
		public Integer listPrice;
	}

	public class OtherCosts {
		public Integer buyout;
		public Integer software;
		public Integer maintenance;
		public Integer shipping;
		public Integer installation;
		public Integer wiring;
		public Integer warranty;
		public Integer miscellaneous;
	}

	
	public static JSONDODGetAssetsUpdate parse(String json) {
		return (JSONDODGetAssetsUpdate) System.JSON.deserialize(json, JSONDODGetAssetsUpdate.class);
	}
}