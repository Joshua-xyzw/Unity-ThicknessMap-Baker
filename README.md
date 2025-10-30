
<img width="913" height="510" alt="最终效果" src="https://github.com/user-attachments/assets/5ba40eb9-01d5-462a-96c2-a10d4005c7a1" />
This is a thicknessmap baker tool in UnityEditor.Use ray-method and bvh to calculate the thickness.
This project also include a surface translucent shader,with single/double face rendering and dither transparent.

This project is developed in Unity 2022.1.23.Using built-in pipeline.

# How to use

Open the Editor window in the top of the UnityEditor,by Window/OpenThicknessBaker.

<img width="725" height="440" alt="image" src="https://github.com/user-attachments/assets/3c1677c2-cd19-4dba-b11b-cf148a6ab9ae" />

<b>Meshfilter</b> : Assign the mesh you want to bake.

<b>TextureSize</b>: Set the texture size you want to bake.

<b>ComputeShader</b>: You must assign Shaders/BakeThicknessCS.compute.

<b>DepthMultiply</b>: It is a thickness scale value. If your texture is overall bright without any difference in brightness, try reducing this value and baking it again.

<b>Exponent</b>: Exponent is an exponential correction that adjusts the overall brightness and darkness values of the final texture.


Only after assigning the mesh you can press "BuildBVH" button to build bvh. After replacing the mesh, bvh must be build again.
only after building bvh youcan press "Bake Thickness Map"

# About the shader
The light transmission effect of the material requires a light behind it, and the light behind should not turn on shadows, otherwise it cannot penetrate.

<img width="421" height="116" alt="image" src="https://github.com/user-attachments/assets/3ef364fe-da45-49f8-91fb-29c178bb75ca" />

<b>SSSScale</b> : This parameter is the color of the scatter,support HDR.

<b>SSSScale</b> : This parameter is a mixed value of translucent. You can adjust this parameter to 1.0 then adjust other parameters to simply observe the effect of translucent, and then reduce this parameter to get the final effect.

<b>SSSDistortion</b>: This parameter refers to the disturb of the direction of the backlight source. The larger this parameter, the smaller the range of the backlight can be observed, and the more intense the change with the observation angle.

<b>SSSPower</b> : This parameter is an exponential parameter of backlight brightness, which can also control the diffusion range of backlight brightness changes

<b>SSSRadius</b> :This parameter controls the Surface Scattering Reflectance(BSSDF),the light that pops up after scattering at the lighting position.

<img width="418" height="122" alt="image" src="https://github.com/user-attachments/assets/fbc9d58e-63fe-459d-bdff-0ad33caef1a7" />

