# EdgeBoard

#### Description

##### petalinux-config
Serial 	  => uart1 115200
Ethernet  => 192.168.0.169 255.255.255.0 192.168.0.1
QSPI      => 0x100000 0x40000 0x1600000
SD/SDIO   => SD_1
BOOT MODE => SD

##### device tree
/* disable sd_1 wp pin */
&sdhci1 {
	status = "okay";
	max-frequency = <50000000>;
	no-1-8-v; /* for 1.0 silicon */
	disable-wp;
};

##### petalinux-packet
cd ./images/linux/
petalinux-package --boot --fsbl zynqmp_fsbl.elf --fpga system.bit --u-boot --pmufw pmufw.elf --force



##### USB HOST
&dwc3_0 {
	status = "okay";
	dr_mode = "host";

	/* dr_mode = "host"; */
	/* dr_mode = "peripheral"; */
};

mkfs.vfat /dev/sd*

USB2.0 3.0 => input => /dev/sda or /dev/sdb or /dev/sdb1

mount /dev/sd* /mnt/sd*

##### /images/BOOT/
boot files, copy to sd, run time.