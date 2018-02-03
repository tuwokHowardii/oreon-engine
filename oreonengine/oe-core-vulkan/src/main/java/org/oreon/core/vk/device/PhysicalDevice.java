package org.oreon.core.vk.device;

import static org.lwjgl.system.MemoryUtil.memAllocInt;
import static org.lwjgl.system.MemoryUtil.memAllocPointer;
import static org.lwjgl.system.MemoryUtil.memFree;
import static org.lwjgl.vulkan.VK10.VK_SUCCESS;
import static org.lwjgl.vulkan.VK10.vkEnumeratePhysicalDevices;

import java.nio.IntBuffer;
import java.util.List;

import org.lwjgl.PointerBuffer;
import org.lwjgl.vulkan.VkInstance;
import org.lwjgl.vulkan.VkPhysicalDevice;
import org.oreon.core.vk.queue.QueueFamilies;
import org.oreon.core.vk.swapchain.SwapChainCapabilities;
import org.oreon.core.vk.util.DeviceCapabilities;
import org.oreon.core.vk.util.VKUtil;

public class PhysicalDevice {

	private VkPhysicalDevice deviceHandle;
	private QueueFamilies queueFamilies;
	private SwapChainCapabilities swapChainCapabilities;
	private List<String> supportedExtensionNames;
	
	public PhysicalDevice(VkInstance vkInstance, long surface) {

		IntBuffer pPhysicalDeviceCount = memAllocInt(1);
        int err = vkEnumeratePhysicalDevices(vkInstance, pPhysicalDeviceCount, null);
        if (err != VK_SUCCESS) {
            throw new AssertionError("Failed to get number of physical devices: " + VKUtil.translateVulkanResult(err));
        }
        
        System.out.println("Available Physical Devices: " + pPhysicalDeviceCount.get(0));
        
        PointerBuffer pPhysicalDevices = memAllocPointer(pPhysicalDeviceCount.get(0));
        err = vkEnumeratePhysicalDevices(vkInstance, pPhysicalDeviceCount, pPhysicalDevices);
        long physicalDevice = pPhysicalDevices.get(0);
       
        if (err != VK_SUCCESS) {
            throw new AssertionError("Failed to get physical devices: " + VKUtil.translateVulkanResult(err));
        }
        
        memFree(pPhysicalDeviceCount);
        memFree(pPhysicalDevices);
        
        deviceHandle =  new VkPhysicalDevice(physicalDevice, vkInstance);
        queueFamilies = new QueueFamilies(deviceHandle, surface);
        swapChainCapabilities = new SwapChainCapabilities(deviceHandle, surface);
        supportedExtensionNames = DeviceCapabilities.getPhysicalDeviceExtensionNamesSupport(deviceHandle);
	}
	
	public void checkExtensionsSupport(PointerBuffer ppEnabledExtensionNames){
		
		for (int i=0; i<ppEnabledExtensionNames.limit(); i++){
			if (!supportedExtensionNames.contains(ppEnabledExtensionNames.getStringUTF8())){
				throw new AssertionError("Extension " + ppEnabledExtensionNames.getStringUTF8() + " not supported");
			}
		}
		
		ppEnabledExtensionNames.flip();
	}

	public QueueFamilies getQueueFamilies() {
		return queueFamilies;
	}

	public VkPhysicalDevice getDeviceHandle() {
		return deviceHandle;
	}

	public SwapChainCapabilities getSwapChainCapabilities() {
		return swapChainCapabilities;
	}

}
