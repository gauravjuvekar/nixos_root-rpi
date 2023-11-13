let
  rpi_sc_gjuvekar_com = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPtEyOzw78nPAFZAE+mqNB4/SyEBV6DSy8+s2Gzuf1++ root@rpi";
in
{
  "hostapd_wpa_password.age".publicKeys = [ rpi_sc_gjuvekar_com ];
}
