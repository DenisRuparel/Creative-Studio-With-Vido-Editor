"use client"

import { uploadImage } from "@/server/upload-image"
import { useImageStore } from "@/lib/store"
import { useDropzone } from "react-dropzone"
import Lottie from "lottie-react"
import { Card, CardContent } from "../ui/card"
import { cn } from "@/lib/utils"
import { useLayerStore } from "@/lib/layer-store"
import imageAnimation from "@/public/animations/image-upload.json"
import { toast } from "sonner"

export default function UploadImage() {
  const setTags = useImageStore((state) => state.setTags)
  const setGenerating = useImageStore((state) => state.setGenerating)
  const activeLayer = useLayerStore((state) => state.activeLayer)
  const updateLayer = useLayerStore((state) => state.updateLayer)
  const setActiveLayer = useLayerStore((state) => state.setActiveLayer)

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    maxFiles: 1,
    accept: {
      "image/png": [".png"],
      "image/jpg": [".jpg"],
      "image/webp": [".webp"],
      "image/jpeg": ["jpeg"],
    },
    onDrop: async (acceptedFiles, fileRejections) => {
      if (acceptedFiles.length) {
        const file = acceptedFiles[0];
    
        if (file.size > 5242880) {
          toast.error("Image size should not exceed 5 MB.");
          return;
        }

        const formData = new FormData()
        formData.append("image", acceptedFiles[0])
        //Generate Object url
        const objectUrl = URL.createObjectURL(acceptedFiles[0])
        setGenerating(true)

        updateLayer({
          id: activeLayer.id,
          url: objectUrl,
          width: 0,
          height: 0,
          name: "uploading",
          publicId: "",
          format: "",
          resourceType: "image",
        })
        setActiveLayer(activeLayer.id)
        const res = await uploadImage({ image: formData })

        if (res?.data?.success) {
          const cloudinaryResult = res.data.success
          // Ensure format doesn't have leading dot
          const format = cloudinaryResult.format?.startsWith('.') 
            ? cloudinaryResult.format.slice(1) 
            : cloudinaryResult.format || 'jpg'
          
          // Use original_filename or fallback to public_id or filename
          const filename = cloudinaryResult.original_filename || 
                          cloudinaryResult.public_id?.split('/').pop() || 
                          file.name?.replace(/\.[^/.]+$/, '') || 
                          'image'
          
          updateLayer({
            id: activeLayer.id,
            url: cloudinaryResult.secure_url || cloudinaryResult.url,
            width: cloudinaryResult.width || 0,
            height: cloudinaryResult.height || 0,
            name: filename,
            publicId: cloudinaryResult.public_id,
            format: format,
            resourceType: cloudinaryResult.resource_type || 'image',
          })
          
          if (cloudinaryResult.tags) {
            setTags(cloudinaryResult.tags)
          }

          setActiveLayer(activeLayer.id)
          console.log("Upload successful:", cloudinaryResult)
          setGenerating(false)
        }
        if (res?.data?.error) {
          console.error("Upload error:", res.data.error)
          toast.error(res.data.error || "Failed to upload image")
          setGenerating(false)
        }
        if (res?.serverError) {
          console.error("Server error:", res.serverError)
          toast.error("Server error: " + res.serverError)
          setGenerating(false)
        }
      }

      if (fileRejections.length) {
        console.log("rejected")
        toast.error(fileRejections[0].errors[0].message)
      }
    },
  })

  if (!activeLayer.url)
    return (
      <Card
        {...getRootProps()}
        className={cn(
          " hover:cursor-pointer hover:bg-secondary hover:border-primary transition-all  ease-in-out ",
          `${isDragActive ? "animate-pulse border-primary bg-secondary" : ""}`
        )}
      >
        <CardContent className="flex flex-col h-full items-center justify-center px-2 py-24  text-xs ">
          <input {...getInputProps()} />
          <div className="flex items-center flex-col justify-center gap-4">
            <Lottie className="h-48" animationData={imageAnimation} />
            <p className="text-muted-foreground text-2xl">
              {isDragActive
                ? "Drop your image here!"
                : "Start by uploading an image"}
            </p>
            <p className="text-muted-foreground">
              Supported Formats .jpeg .jpg .png .webp
            </p>
          </div>
        </CardContent>
      </Card>
    )
}