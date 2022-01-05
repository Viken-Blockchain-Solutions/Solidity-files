// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Structs {
   
   // Structs are used to contain data.

   // Data in struct.
   struct Car {
      string model;
      uint256 year;
      address owner;
      bool inGarage;
   }

   /** We can use a struct as state variables as shown below */
   Car public car;   // a variable.
   Car[] public cars; // an array of cars.
   mapping(address => Car[]) public carsByOwner; // an mapping contain an array of cars ByOwner

   /**
   * @notice setExamples shows different ways we can initialise a struct.
   */
   function setExamples() external {
      // The standard way.
      Car memory mercedesBenz = Car( // memory = exists only inside of the function. 
         "E190",     // model
         1996,       // year
         msg.sender, // owner
         true        // inGarage
      );

      // As an object in curly brackets.
      Car memory ferrari = Car({       // initialise as an object
         year: 2010,                   // in an object, the order is not relevant
         model: "360 Modena",
         inGarage: false,
         owner: msg.sender
      });

      // With only default values
      Car memory tesla;
      tesla.model = "Model S";
      tesla.year = 2020;
      tesla.owner = msg.sender;
      tesla.inGarage = true;
      

      // Because of "memory", we need to add the stucts to a statevariable 
      cars.push(mercedesBenz);
      cars.push(ferrari);
      cars.push(tesla);

      cars.push(Car("Toyota", 1999, msg.sender, false));
   }

   /**
   * @notice getExamples shows different ways we can get info from a struct.
   */
   function GetExamples() external view returns (string memory, uint256, address, bool) {
      Car memory _car = cars[0];
      return (_car.model, _car.year, _car.owner, _car.inGarage);
   }

   /**
   * @notice updateExamples shows different ways we can update data in a struct.
   */
   function updateExamples() external {
      Car storage _car = cars[0];
      _car.year = 1999;
   }

   /**
   * @notice deleteExamples shows different ways we can delete data in a struct.
   */
   function deleteExamples() external {
      Car storage _c = cars[1];
      delete _c.owner;

      delete cars[1];
   }
}