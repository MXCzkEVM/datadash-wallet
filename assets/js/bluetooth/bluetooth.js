class BluetoothCharacteristicProperties {
  constructor(
    broadcast,
    read,
    writeWithoutResponse,
    write,
    notify,
    indicate,
    authenticatedSignedWrites,
    reliableWrite,
    writableAuxiliaries
  ) {
    this.broadcast = broadcast;
    this.read = read;
    this.writeWithoutResponse = writeWithoutResponse;
    this.write = write;
    this.notify = notify;
    this.indicate = indicate;
    this.authenticatedSignedWrites = authenticatedSignedWrites;
    this.reliableWrite = reliableWrite;
    this.writableAuxiliaries = writableAuxiliaries;
  }
}

class BluetoothDevice extends EventTarget {
  constructor(id, name, gatt, watchingAdvertisements) {
    super();
    this.id = id;
    this.name = name;
    this.gatt = gatt;
    this.watchingAdvertisements = watchingAdvertisements;
  }

  async watchAdvertisements() {
    const response = await window.axs.callHandler(
      "BluetoothDevice.watchAdvertisements"
    );
    return response;
  }

  async forget() {
    const response = await window.axs.callHandler("BluetoothDevice.forget");
    return response;
  }
}

class BluetoothRemoteGATTServer extends EventTarget {
  constructor(device, connected) {
    super();
    this.device = device;
    this.connected = connected;
  }

  async connect() {
    const resp = await window.axs?.callHandler(
      "BluetoothRemoteGATTServer.connect",
      {}
    );
    this.device = resp.device;
    this.connected = resp.connected;
    return this;
  }

  async disconnect() {
    await window.axs.callHandler("BluetoothRemoteGATTServer.disconnect", {});
  }

  async getPrimaryService(service) {
    const data = { service: service };
    const resp = await window.axs?.callHandler(
      "BluetoothRemoteGATTServer.getPrimaryService",
      data
    );
    const respService = new BluetoothRemoteGATTService(
      resp.device,
      resp.uuid,
      resp.isPrimary
    );
    navigator.bluetooth.serviceArray.push(respService);
    return respService;
  }

  async getPrimaryServices(service) {
    const data = { service: service };
    const response = await window.axs.callHandler(
      "BluetoothRemoteGATTServer.getPrimaryServices",
      data
    );
    return response;
  }
}

class BluetoothRemoteGATTCharacteristic extends EventTarget {
  constructor(service, uuid, value, properties) {
    super();
    this.service = service;
    this.uuid = uuid;
    this.value = value;
    this.properties = properties;
  }

  async getDescriptor(descriptor) {
    const data = {
      this: this.uuid,
      serviceUUID: this.service.uuid,
      descriptor: descriptor,
    };
    const response = await window.axs.callHandler(
      "BluetoothRemoteGATTCharacteristic.getDescriptor",
      data
    );
    return response;
  }

  async getDescriptors(descriptor) {
    const data = {
      this: this.uuid,
      serviceUUID: this.service.uuid,
      descriptor: descriptor,
    };

    const response = await window.axs.callHandler(
      "BluetoothRemoteGATTCharacteristic.getDescriptors",
      data
    );
    return response;
  }
  async readValue() {
    const data = { this: this.uuid, serviceUUID: this.service.uuid };
    const response = await window.axs.callHandler(
      "BluetoothRemoteGATTCharacteristic.readValue",
      data
    );
    return response;
  }

  async writeValue(value) {
    const data = {
      this: this.uuid,
      serviceUUID: this.service.uuid,
      value: value,
    };

    await window.axs.callHandler(
      "BluetoothRemoteGATTCharacteristic.writeValue",
      data
    );
  }

  async writeValueWithResponse(value) {
    const data = {
      this: this.uuid,
      serviceUUID: this.service.uuid,
      value: value,
    };

    await window.axs.callHandler(
      "BluetoothRemoteGATTCharacteristic.writeValueWithResponse",
      data
    );
  }

  async writeValueWithoutResponse(value) {
    const data = {
      this: this.uuid,
      serviceUUID: this.service.uuid,
      value: value,
    };

    await window.axs.callHandler(
      "BluetoothRemoteGATTCharacteristic.writeValueWithoutResponse",
      data
    );
  }

  async startNotifications() {
    const data = { this: this.uuid, serviceUUID: this.service.uuid };

    await window.axs.callHandler(
      "BluetoothRemoteGATTCharacteristic.startNotifications",
      data
    );
    return this;
  }

  async stopNotifications() {
    const data = { this: this.uuid, serviceUUID: this.service.uuid };

    await window.axs.callHandler(
      "BluetoothRemoteGATTCharacteristic.stopNotifications",
      data
    );
    return this;
  }

  addEventListener(type, listener, useCapture = false) {
    // Custom addEventListener implementation to handle specific types
    super.addEventListener(type, listener, useCapture);
  }
}

class BluetoothRemoteGATTService extends EventTarget {
  constructor(device, uuid, isPrimary) {
    super();
    this.device = device;
    this.uuid = uuid;
    this.isPrimary = isPrimary;
  }

  async getCharacteristic(characteristic) {
    let data = { this: this.uuid, characteristic: characteristic };
    console.log("Service changed: ", JSON.stringify(data));
    const resp = await window.axs?.callHandler(
      "BluetoothRemoteGATTService.getCharacteristic",
      data
    );
    console.log("Service changed:4 ", resp);
    const characteristicInstance = new BluetoothRemoteGATTCharacteristic(
      this,
      resp.uuid,
      resp.value,
      undefined
    );
    navigator.bluetooth.characteristicArray.push(characteristicInstance);
    // resp.startNotifications = eval(resp.startNotifications);
    return characteristicInstance;
  }

  async getCharacteristics(characteristic) {
    const response = await window.axs.callHandler(
      "BluetoothRemoteGATTService.getCharacteristics",
      { this: "$uuid", characteristic: characteristic }
    );
    return response;
  }

  async getIncludedService(service) {
    const response = await window.axs.callHandler(
      "BluetoothRemoteGATTService.getIncludedService",
      { this: "$uuid", service: service }
    );
    return response;
  }

  async getIncludedServices(service) {
    const response = await window.axs.callHandler(
      "BluetoothRemoteGATTService.getIncludedServices",
      { this: "$uuid", service: service }
    );
    return response;
  }

  addEventListener(type, listener, useCapture = false) {
    // Custom addEventListener implementation to handle specific types
    super.addEventListener(type, listener, useCapture);
  }
}

class AXSBluetooth {
  constructor() {
    this.serviceArray = [];
    this.characteristicArray = [];
    this.bluetoothDevice = {};
  }

  async requestDevice(options) {
    const resp = await window.axs?.callHandler("requestDevice", options);

    const gatt = new BluetoothRemoteGATTServer(
      resp.gatt.device,
      resp.gatt.connected
    );

    const device = new BluetoothDevice(
      resp.id,
      resp.name,
      gatt,
      resp.watchingAdvertisements
    );

    return device;
  }

  dispatchCharacteristicEvent(characteristicUUID, eventName) {
    let selectedCharacteristic =
      this.getCharacteristicByUUID(characteristicUUID);
    console.log("X");
    if (selectedCharacteristic != undefined) {
      console.log("X1");
      selectedCharacteristic.dispatchEvent(new Event(eventName));
      console.log("X2");
    }
  }

  updateCharacteristicValue(characteristicUUID, base64String) {
    const binaryString = atob(base64String);
    const len = binaryString.length;
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    let selectedCharacteristic =
      this.getCharacteristicByUUID(characteristicUUID);
    selectedCharacteristic.value = dv;
    this.dispatchCharacteristicEvent(
      characteristicUUID,
      "characteristicvaluechanged"
    );
  }

  getServiceByUUID(serviceUUID) {
    return this.serviceArray.find((service) => service.uuid === serviceUUID);
  }

  getCharacteristicByUUID(characteristicUUID) {
    return this.characteristicArray.find(
      (characteristic) => characteristic.uuid === characteristicUUID
    );
  }
}

navigator.bluetooth = new AXSBluetooth();
console.log("hallo");
console.log(JSON.stringify(navigator.bluetooth, null, 2));

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