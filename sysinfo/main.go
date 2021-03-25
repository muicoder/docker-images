package main

import (
	"fmt"
	"math"
	"strconv"

	"github.com/shirou/gopsutil/cpu"
	"github.com/shirou/gopsutil/disk"
	"github.com/shirou/gopsutil/host"
	"github.com/shirou/gopsutil/mem"
)

func roundFloat(number float64, decimalPlaces int) string {
	return strconv.FormatFloat(math.Round(number*math.Pow(10.0, float64(decimalPlaces)))/math.Pow(10.0, float64(decimalPlaces)), 'f', -1, 64)
}

func main() {
	// get OS information
	osInfo, _ := host.Info()

	// get cpu information
	cpuCoresLogical, _ := cpu.Counts(true)
	cpuCoresPhysical, _ := cpu.Counts(false)
	cpuInfo, _ := cpu.Info()

	// get memory information
	memory, _ := mem.VirtualMemory()

	// get disks information
	disks, _ := disk.Partitions(false)

	// print information
	println("Hostname:", osInfo.Hostname)
	println("OS:", osInfo.OS)
	println("Platform:", osInfo.Platform)
	println("PlatformFamily:", osInfo.PlatformFamily)
	println("PlatformVersion:", osInfo.PlatformVersion)
	println("KernelArch:", osInfo.KernelArch)
	println("KernelVersion:", osInfo.KernelVersion)
	println()
	println("number of processes:", osInfo.Procs)
	println()

	// CPU
	fmt.Printf("CPU:(%d/%d)\t %s\n",
		cpuCoresPhysical,
		cpuCoresLogical,
		cpuInfo[0].ModelName,
	)

	// memory
	memoryGi := float64(memory.Total) / (1 << 30)
	if memoryGi < 1 {
		fmt.Printf("Memory:\t %s Mb/ %sMb (%s%%)\n",
			roundFloat(float64(memory.Used)/(1<<20), 3),
			roundFloat(float64(memory.Total)/(1<<20), 3),
			roundFloat(memory.UsedPercent, 2),
		)
	} else {
		if memoryGi < 1024 {
			fmt.Printf("Memory:\t %s Gb/ %sGb (%s%%)\n",
				roundFloat(float64(memory.Used)/(1<<30), 3),
				roundFloat(float64(memory.Total)/(1<<30), 3),
				roundFloat(memory.UsedPercent, 2),
			)
		} else {
			fmt.Printf("Memory:\t %s Tb/ %sTb (%s%%)\n",
				roundFloat(float64(memory.Used)/(1<<40), 3),
				roundFloat(float64(memory.Total)/(1<<40), 3),
				roundFloat(memory.UsedPercent, 2),
			)
		}
	}

	// disks
	fmt.Print("Disks: ")
	for _, d := range disks {
		device, _ := disk.Usage(d.Mountpoint)
		deviceGi := float64(device.Total) / (1 << 30)
		if deviceGi < 1 {
			fmt.Printf("\t %s: %s Mb/ %sMb (%s%%) - %s\n",
				d.Device,
				roundFloat(float64(device.Used)/(1<<20), 3),
				roundFloat(float64(device.Total)/(1<<20), 3),
				roundFloat(device.UsedPercent, 2),
				device.Fstype)
		} else {
			if deviceGi < 1024 {
				fmt.Printf("\t %s: %sGb / %sGb (%s%%) - %s\n",
					d.Device,
					roundFloat(float64(device.Used)/(1<<30), 3),
					roundFloat(float64(device.Total)/(1<<30), 3),
					roundFloat(device.UsedPercent, 2),
					device.Fstype)
			} else {
				fmt.Printf("\t %s: %sTb / %sTb (%s%%) - %s\n",
					d.Device,
					roundFloat(float64(device.Used)/(1<<40), 3),
					roundFloat(float64(device.Total)/(1<<40), 3),
					roundFloat(device.UsedPercent, 2),
					device.Fstype)
			}
		}
	}
}
