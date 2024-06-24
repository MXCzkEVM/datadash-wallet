class AXSBluetooth {
  constructor() {
    this.serviceArray = [];
    this.characteristicArray = [];
    this.bluetoothDevice = {};
    const self = this;
    this.bluetoothRemoteGATTServer = {
      connect: async () => {
        var resp = await window.axs?.callHandler(
          "BluetoothRemoteGATTServer.connect",
          {}
        );
        resp.getPrimaryService = eval(resp.getPrimaryService);
        return resp;
      },

      getPrimaryService: async (data) => {
        console.log("Service changed5465: ",  JSON.stringify(data));
        var resp = await window.axs?.callHandler(
          "BluetoothRemoteGATTServer.getPrimaryService",
          data
        );
        self.serviceArray.push(resp);
        console.log("Service changed:2 ",);
        resp.getCharacteristic = eval(resp.getCharacteristic);
        return resp;
      },
    };

    this.bluetoothRemoteGATTService = {
      getCharacteristic: async (data) => {
        console.log("Service changed: ",  JSON.stringify(data));
        var resp = await window.axs?.callHandler(
          "BluetoothRemoteGATTService.getCharacteristic",
          data
        );
        console.log("Service changed:3 ",  resp);
        this.characteristicArray.push(resp);
        resp.startNotifications = eval(resp.startNotifications);
        return resp;
      },
    };

    this.bluetoothRemoteGATTCharacteristic = {
      startNotifications: async (data) => {
        var resp = await window.axs?.callHandler(
          "BluetoothRemoteGATTService.startNotifications",
          data
        );
        console.log("Service changed:3 ",  resp);
        resp.startNotifications = eval(resp.startNotifications);
        return resp;
      }
    }
  }

  async requestDevice(options) {
    var resp = await window.axs?.callHandler("requestDevice", options);
    

    resp.gatt.connect = eval(resp.gatt.connect);
    return resp;
  }
}

// class BluetoothRemoteGATTService extends EventTarget {
//   constructor(device, uuid, isPrimary) {
//     super();
//     this.device = device;
//     this.uuid = uuid;
//     this.isPrimary = isPrimary;
//   }

//   async getCharacteristic(characteristic) {}

//   async getCharacteristics(characteristic) {}

//   async getIncludedService(service) {}

//   async getIncludedServices(service) {}

//   addEventListener(type, listener, useCapture = false) {
//     // Custom addEventListener implementation to handle specific types
//     super.addEventListener(type, listener, useCapture);
//   }
// }

navigator.bluetooth = new AXSBluetooth();
console.log("hallo");
console.log(JSON.stringify(navigator.bluetooth , null, 2));

//   window.bluetooth.requestDevice();
// window.axs.bluetooth.bluetoothDevice =
// window.bluetooth.bluetoothDevice.

// Simulated classes for completeness
// class BluetoothRemoteGATTCharacteristic {
//   constructor(uuid) {
//     this.uuid = uuid;
//   }
// }

// var serviceCopy;

// Usage example
// const device = { name: "Device1" };
// const service = new BluetoothRemoteGATTService(device, "1234", true);
// console.log(JSON.stringify(service));

// service.addEventListener("serviceadded", (ev) => {
//   console.log("Service added:", ev);
//   console.log("data:", ev.detail);
//   ev.detail.dispatchEvent(new Event("servicechanged"));
// });

// service.addEventListener("servicechanged", (ev) => {
//   console.log("Service changed:", ev);
// });

// service.addEventListener("serviceremoved", (ev) => {
//   console.log("Service removed:", ev);
// });

// {"device":{"name":"Device1"},"uuid":"1234","isPrimary":true}

// {device: {name: "Device1"}, uuid: 1234, isPrimary: true}
// Dispatching events for testing
// service.dispatchEvent(new Event("serviceadded"));
// service.dispatchEvent(new Event("servicechanged"));
// service.dispatchEvent(new Event("serviceremoved"));

// hello() {
//   const customEvent = new CustomEvent("serviceadded", { detail: this });
//   this.dispatchEvent(customEvent);
// }

// async helloToFlutter() {
//   serviceCopy = this;
//   await window.axs?.callHandler("helloToFlutter", serviceCopy);
//   this.addEventListener("serviceadded", (ev) => {
//     console.log("Here is the ");
//     console.log("Service added:", ev);
//     console.log("data:", ev.detail);
//     ev.detail.dispatchEvent(new Event("servicechanged"));
//   });
// }
